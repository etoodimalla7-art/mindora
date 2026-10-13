"""Orchestrates the document lifecycle: upload, analysis, submission."""
from __future__ import annotations

import logging
import uuid
from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import (
    ConflictError,
    ForbiddenError,
    NotFoundError,
    ValidationError,
)
from app.models.document import (
    DOC_STATUS_APPROVED,
    DOC_STATUS_NEEDS_REVISION,
    DOC_STATUS_REJECTED,
    DOC_STATUS_UNDER_REVIEW,
    DOC_STATUS_UPLOADING,
    DescriptionValidation,
    Document,
    DocumentAnalysis,
)
from app.repositories.document_repo import DocumentRepository
from app.schemas.document import (
    DocumentAnalysisOut,
    DocumentDetail,
    DocumentDuplicateOut,
    DocumentOut,
    DocumentStatusOut,
    SubmitDocumentRequest,
)
from app.services.document_analysis import analyze_document
from app.services.document_dedup import (
    content_hash,
    find_duplicates,
    has_blocking_duplicate,
    text_hash,
)
from app.services.document_extraction import extract_text
from app.services.description_validator import validate_description

logger = logging.getLogger(__name__)

# Max size for BYTEA storage in Phase 6 (10 MB).
MAX_UPLOAD_BYTES = 10 * 1024 * 1024

ALLOWED_MIME_TYPES = {
    "application/pdf",
    "text/plain",
    "text/markdown",
    "image/png",
    "image/jpeg",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}


class DocumentService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.repo = DocumentRepository(session)

    # ---------- Upload ----------

    async def upload(
        self,
        *,
        owner_id: uuid.UUID,
        filename: str,
        mime_type: str,
        content: bytes,
        title: str,
        description: str,
    ) -> DocumentOut:
        # 1. Validate the file at the boundary.
        if not content:
            raise ValidationError("The file is empty.")
        if len(content) > MAX_UPLOAD_BYTES:
            raise ValidationError(
                f"File is too large. Maximum size is "
                f"{MAX_UPLOAD_BYTES // (1024 * 1024)} MB."
            )
        if mime_type not in ALLOWED_MIME_TYPES:
            raise ValidationError(
                "Unsupported file type. Please upload a PDF, DOCX, image, "
                "or plain-text document."
            )

        # 2. Validate the description (500+ words, non-spam).
        validation = validate_description(description)
        if not validation.passed:
            raise ValidationError(
                validation.failure_reason or "Description is invalid."
            )

        # 3. Extract text early so hashing is meaningful.
        extraction = extract_text(content, mime_type)
        c_hash = content_hash(content)
        t_hash = text_hash(extraction.text) if extraction.text else None

        # 4. Create the row.
        doc = Document(
            owner_id=owner_id,
            title=title.strip(),
            description=description,
            original_filename=filename,
            mime_type=mime_type,
            size_bytes=len(content),
            content=content,
            page_count=extraction.page_count,
            extracted_text=extraction.text or None,
            content_hash=c_hash,
            text_hash=t_hash,
            status=DOC_STATUS_UPLOADING,
        )
        await self.repo.create(doc)

        # 5. Record the description validation.
        self.session.add(
            DescriptionValidation(
                document_id=doc.id,
                word_count=validation.word_count,
                unique_word_count=validation.unique_word_count,
                repetition_ratio=validation.repetition_ratio,
                passed=validation.passed,
            )
        )

        await self.repo.commit()
        await self.repo.refresh(doc)
        return DocumentOut.model_validate(doc)

    # ---------- Submit (analysis + classification) ----------

    async def submit(
        self,
        *,
        owner_id: uuid.UUID,
        doc_id: uuid.UUID,
        payload: SubmitDocumentRequest,
    ) -> DocumentDetail:
        doc = await self.repo.get(doc_id, owner_id)
        if not doc:
            raise NotFoundError("Document not found.")
        if doc.status not in (
            DOC_STATUS_UPLOADING,
            DOC_STATUS_NEEDS_REVISION,
            DOC_STATUS_REJECTED,
        ):
            raise ConflictError(
                f"This document is already in state '{doc.status}'."
            )

        # Merge user-declared metadata.
        self._apply_declared_metadata(doc, payload)

        # Run the analysis pipeline.
        analysis_result = await analyze_document(
            text=doc.extracted_text or "",
            title=doc.title,
            description=doc.description,
            declared_language=doc.language,
            declared_subject=doc.category,
            declared_level=doc.academic_level,
        )

        # Persist (or update) the analysis row.
        existing = doc.analysis
        if existing is None:
            doc.analysis = DocumentAnalysis(
                document_id=doc.id,
                detected_language=analysis_result.detected_language,
                language_confidence=analysis_result.language_confidence,
                detected_subject=analysis_result.detected_subject,
                subject_confidence=analysis_result.subject_confidence,
                detected_level=analysis_result.detected_level,
                level_confidence=analysis_result.level_confidence,
                detected_doc_type=analysis_result.detected_doc_type,
                doc_type_confidence=analysis_result.doc_type_confidence,
                is_spam=analysis_result.is_spam,
                is_inappropriate=analysis_result.is_inappropriate,
                contains_pii=analysis_result.contains_pii,
                quality_score=analysis_result.quality_score,
                keywords=analysis_result.keywords,
                summary=analysis_result.summary,
                raw_response=analysis_result.raw_response,
            )
        else:
            existing.detected_language = analysis_result.detected_language
            existing.language_confidence = analysis_result.language_confidence
            existing.detected_subject = analysis_result.detected_subject
            existing.subject_confidence = analysis_result.subject_confidence
            existing.detected_level = analysis_result.detected_level
            existing.level_confidence = analysis_result.level_confidence
            existing.detected_doc_type = analysis_result.detected_doc_type
            existing.doc_type_confidence = analysis_result.doc_type_confidence
            existing.is_spam = analysis_result.is_spam
            existing.is_inappropriate = analysis_result.is_inappropriate
            existing.contains_pii = analysis_result.contains_pii
            existing.quality_score = analysis_result.quality_score
            existing.keywords = analysis_result.keywords
            existing.summary = analysis_result.summary
            existing.raw_response = analysis_result.raw_response

        # Duplicate detection.
        dupes = await find_duplicates(self.session, doc)
        # Clear previous duplicates on resubmission.
        for existing_dup in list(doc.duplicates or []):
            await self.session.delete(existing_dup)
        for d in dupes:
            self.session.add(d)

        # Decide the final status.
        if has_blocking_duplicate(dupes):
            doc.status = DOC_STATUS_REJECTED
            doc.rejection_reason = (
                "This document appears to be an exact duplicate of an "
                "existing submission."
            )
        elif analysis_result.is_spam or analysis_result.is_inappropriate:
            doc.status = DOC_STATUS_REJECTED
            doc.rejection_reason = (
                "The document was flagged by our moderation checks."
            )
        else:
            doc.status = DOC_STATUS_UNDER_REVIEW

        doc.quality_score = analysis_result.quality_score

        await self.repo.commit()
        refreshed = await self.repo.get(doc_id, owner_id)
        return self._to_detail(refreshed)

    # ---------- Read ----------

    async def get(self, owner_id: uuid.UUID, doc_id: uuid.UUID) -> DocumentDetail:
        doc = await self.repo.get(doc_id, owner_id)
        if not doc:
            raise NotFoundError("Document not found.")
        return self._to_detail(doc)

    async def get_status(
        self, owner_id: uuid.UUID, doc_id: uuid.UUID
    ) -> DocumentStatusOut:
        doc = await self.repo.get(doc_id, owner_id)
        if not doc:
            raise NotFoundError("Document not found.")
        return DocumentStatusOut(
            id=doc.id,
            status=doc.status,
            steps=_steps_for(doc),
            rejection_reason=doc.rejection_reason,
        )

    async def list_mine(self, owner_id: uuid.UUID) -> list[DocumentOut]:
        docs = await self.repo.list_for_owner(owner_id)
        return [DocumentOut.model_validate(d) for d in docs]

    # ---------- Helpers ----------

    def _apply_declared_metadata(
        self, doc: Document, payload: SubmitDocumentRequest
    ) -> None:
        if payload.category is not None:
            doc.category = payload.category
        if payload.academic_level is not None:
            doc.academic_level = payload.academic_level
        if payload.language is not None:
            doc.language = payload.language
        doc.is_exam_related = payload.is_exam_related
        if payload.exam_system is not None:
            doc.exam_system = payload.exam_system
        if payload.exam_name is not None:
            doc.exam_name = payload.exam_name
        if payload.exam_year is not None:
            doc.exam_year = payload.exam_year
        if payload.exam_session is not None:
            doc.exam_session = payload.exam_session
        if payload.document_type is not None:
            doc.document_type = payload.document_type

    def _to_detail(self, doc: Document | None) -> DocumentDetail:
        if doc is None:
            raise NotFoundError("Document not found.")
        analysis = (
            DocumentAnalysisOut.model_validate(doc.analysis)
            if doc.analysis
            else None
        )
        dups = [
            DocumentDuplicateOut.model_validate(d) for d in (doc.duplicates or [])
        ]
        return DocumentDetail(
            **DocumentOut.model_validate(doc).model_dump(),
            analysis=analysis,
            duplicates=dups,
        )


def _steps_for(doc: Document) -> dict[str, str]:
    """Return the checklist shown in the upload progress UI."""
    status = doc.status
    steps: dict[str, str] = {
        "file_validation": "done",
        "text_extraction": "done" if doc.extracted_text else "pending",
        "language_detection": "pending",
        "content_classification": "pending",
        "duplicate_check": "pending",
        "moderation": "pending",
    }
    if status in (DOC_STATUS_UNDER_REVIEW, DOC_STATUS_APPROVED):
        for k in ("language_detection", "content_classification", "duplicate_check"):
            steps[k] = "done"
        steps["moderation"] = "in_progress"
    if status == DOC_STATUS_APPROVED:
        steps["moderation"] = "done"
    if status == DOC_STATUS_REJECTED:
        for k in ("language_detection", "content_classification", "duplicate_check"):
            steps[k] = "done"
        steps["moderation"] = "failed"
    return steps
