from api.core.errors import NotFoundError, DocumentProcessingError, ValidationFailedError
from api.integrations.storage_provider import StorageProvider
from api.integrations.text_extraction import TextExtractionError
from api.modules.documents.analysis_pipeline import DocumentAnalysisPipeline
from api.modules.documents.repository import DocumentsRepository
from api.modules.documents.schemas import DocumentMetadataIn, DocumentExamMetadataIn
from api.modules.documents.validation import validate_description

MAX_FILE_SIZE_BYTES = 25 * 1024 * 1024  # 25 MB
ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg", ".docx"}


class DocumentsService:
    def __init__(self, repo: DocumentsRepository, storage: StorageProvider):
        self.repo = repo
        self.storage = storage

    async def upload(self, uploader_id: str, filename: str, content: bytes):
        # Section 22: never expose raw exceptions — normalize every
        # failure mode to a calm, actionable message.
        if not content:
            raise DocumentProcessingError("This file appears to be empty. Please choose another file.")
        if len(content) > MAX_FILE_SIZE_BYTES:
            raise DocumentProcessingError("This file is too large (max 25 MB).")
        extension = "." + filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
        if extension not in ALLOWED_EXTENSIONS:
            raise DocumentProcessingError(
                "Unsupported file type. Please upload a PDF, Word document, or image."
            )
        try:
            file_key = await self.storage.save(content, filename)
        except Exception as exc:
            raise DocumentProcessingError() from exc  # generic safe message, real detail logged upstream
        return await self.repo.create(uploader_id, file_key, filename)

    async def save_metadata(self, document_id: str, uploader_id: str, payload: DocumentMetadataIn):
        doc = await self._get_owned_or_404(document_id, uploader_id)
        problems = validate_description(payload.description)
        if problems:
            raise ValidationFailedError(" ".join(problems))
        return await self.repo.save_metadata(doc, payload.model_dump())

    async def save_exam_metadata(self, document_id: str, uploader_id: str, payload: DocumentExamMetadataIn):
        await self._get_owned_or_404(document_id, uploader_id)  # ownership check
        return await self.repo.upsert_exam_metadata(document_id, payload.model_dump())

    async def submit(self, document_id: str, uploader_id: str):
        """
        Runs the full section-21 pipeline (extraction -> language ->
        classification -> duplicate check) and decides Approved-track
        (UnderReview) vs NeedsRevision. Returns (document, problems,
        warnings) — problems block approval and must be fixed;
        warnings (mismatched category, possible duplicate) are recorded
        for human review but never auto-reject a legitimate submission
        (section 25).
        """
        doc = await self._get_owned_or_404(document_id, uploader_id)
        if not doc.title or not doc.description:
            raise ValidationFailedError("Please complete the document details before submitting.")

        problems = validate_description(doc.description)
        warnings: list[str] = []

        extension = "." + doc.original_filename.rsplit(".", 1)[-1].lower()
        try:
            file_content = await self.storage.read(doc.file_key)
        except Exception as exc:
            raise DocumentProcessingError() from exc

        pipeline = DocumentAnalysisPipeline(self.repo.list_other_analyses_for_duplicate_check)
        try:
            result = await pipeline.run(
                document_id=document_id,
                file_extension=extension,
                file_content=file_content,
                declared_language=doc.language,
            )
        except TextExtractionError as exc:
            raise DocumentProcessingError(str(exc)) from exc

        await self.repo.upsert_analysis(document_id, {
            "extracted_text": result.extracted_text[:20000] if result.extracted_text else None,
            "content_hash": result.content_hash,
            "page_count": result.page_count,
            "detected_language": result.detected_language,
            "detected_subject": result.detected_subject,
            "detected_level": result.detected_level,
            "quality_score": result.quality_score,
            "duplicate_of_id": result.duplicate_of_id,
            "similarity_score": result.similarity_score,
        })

        await self.repo.record_validation(
            document_id, "description_length_and_quality", passed=not problems,
            detail="; ".join(problems) or None,
        )

        # Language mismatch (section 20) blocks — the user explicitly
        # declared it, so it must be correct or corrected.
        if result.language_mismatch:
            problems.append(result.language_mismatch)
        await self.repo.record_validation(
            document_id, "language_match", passed=result.language_mismatch is None,
            detail=result.language_mismatch,
        )

        # Metadata consistency (section 24) is a soft flag, not a block —
        # heuristic subject/level detection isn't reliable enough to
        # reject a correct submission over.
        if result.detected_subject and doc.category and result.detected_subject != doc.category:
            warnings.append(
                f"This document looks more like {result.detected_subject} than {doc.category} — "
                "a moderator will double-check the category."
            )
        await self.repo.record_validation(
            document_id, "metadata_consistency",
            passed=(not result.detected_subject or result.detected_subject == doc.category),
            detail=warnings[-1] if warnings and "looks more like" in warnings[-1] else None,
        )

        # Duplicate detection (section 25): flag, never auto-reject.
        if result.duplicate_of_id:
            confidence_pct = round(result.similarity_score * 100)
            warnings.append(f"Potential duplicate detected (similarity: {confidence_pct}%). A moderator will review.")
        await self.repo.record_validation(
            document_id, "duplicate_check", passed=result.duplicate_of_id is None,
            detail=f"similarity={result.similarity_score:.2f}" if result.duplicate_of_id else None,
        )

        if problems:
            await self.repo.set_status(doc, "NeedsRevision")
        else:
            await self.repo.set_status(doc, "UnderReview")
        return doc, problems, warnings

    async def get_status(self, document_id: str, uploader_id: str):
        doc = await self._get_owned_or_404(document_id, uploader_id)
        return doc

    async def list_mine(self, uploader_id: str):
        return await self.repo.list_mine(uploader_id)

    async def _get_owned_or_404(self, document_id: str, uploader_id: str):
        doc = await self.repo.get_owned(document_id, uploader_id)
        if not doc:
            raise NotFoundError("We couldn't find this document.")
        return doc
