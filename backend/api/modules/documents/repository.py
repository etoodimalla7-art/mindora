from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.documents.models import Document, DocumentMetadataExam, DocumentValidation, DocumentAnalysis


class DocumentsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, uploader_id: str, file_key: str, original_filename: str) -> Document:
        doc = Document(
            uploader_id=to_uuid(uploader_id),
            file_key=file_key,
            original_filename=original_filename,
            status="Draft",
        )
        self.db.add(doc)
        await self.db.commit()
        await self.db.refresh(doc)
        return doc

    async def get_owned(self, document_id: str, uploader_id: str) -> Document | None:
        result = await self.db.execute(
            select(Document)
            .where(Document.id == to_uuid(document_id))
            .where(Document.uploader_id == to_uuid(uploader_id))
        )
        return result.scalar_one_or_none()

    async def save_metadata(self, doc: Document, data: dict) -> Document:
        for key, value in data.items():
            setattr(doc, key, value)
        await self.db.commit()
        await self.db.refresh(doc)
        return doc

    async def upsert_exam_metadata(self, document_id: str, data: dict) -> DocumentMetadataExam:
        doc_uuid = to_uuid(document_id)
        result = await self.db.execute(
            select(DocumentMetadataExam).where(DocumentMetadataExam.document_id == doc_uuid)
        )
        existing = result.scalar_one_or_none()
        if existing:
            for key, value in data.items():
                setattr(existing, key, value)
            await self.db.commit()
            await self.db.refresh(existing)
            return existing
        meta = DocumentMetadataExam(document_id=doc_uuid, **data)
        self.db.add(meta)
        await self.db.commit()
        await self.db.refresh(meta)
        return meta

    async def set_status(self, doc: Document, status: str) -> Document:
        doc.status = status
        await self.db.commit()
        await self.db.refresh(doc)
        return doc

    async def record_validation(self, document_id: str, check_name: str, passed: bool, detail: str | None):
        self.db.add(
            DocumentValidation(
                document_id=to_uuid(document_id), check_name=check_name, passed=passed, detail=detail
            )
        )
        await self.db.commit()

    async def list_mine(self, uploader_id: str) -> list[Document]:
        result = await self.db.execute(
            select(Document)
            .where(Document.uploader_id == to_uuid(uploader_id))
            .order_by(Document.created_at.desc())
        )
        return list(result.scalars().all())

    async def upsert_analysis(self, document_id: str, data: dict) -> DocumentAnalysis:
        doc_uuid = to_uuid(document_id)
        result = await self.db.execute(
            select(DocumentAnalysis).where(DocumentAnalysis.document_id == doc_uuid)
        )
        existing = result.scalar_one_or_none()
        if existing:
            for key, value in data.items():
                setattr(existing, key, value)
            await self.db.commit()
            await self.db.refresh(existing)
            return existing
        analysis = DocumentAnalysis(document_id=doc_uuid, **data)
        self.db.add(analysis)
        await self.db.commit()
        await self.db.refresh(analysis)
        return analysis

    async def list_other_analyses_for_duplicate_check(
        self, exclude_document_id: str, limit: int = 200
    ) -> list[tuple[str, str | None, str | None]]:
        """Returns (document_id, content_hash, extracted_text) for other
        documents — feeds duplicate_detection.find_best_match. Capped at
        `limit`; see analysis_pipeline.py's note on swapping to a vector
        index once the corpus outgrows this O(n) scan."""
        result = await self.db.execute(
            select(DocumentAnalysis.document_id, DocumentAnalysis.content_hash, DocumentAnalysis.extracted_text)
            .where(DocumentAnalysis.document_id != to_uuid(exclude_document_id))
            .limit(limit)
        )
        return [(str(row[0]), row[1], row[2]) for row in result.all()]

    async def list_extracted_texts_for_user(self, uploader_id: str) -> list[tuple[str, str]]:
        """Feeds the AI course retriever (Phase 8): a student's own
        uploaded documents that have extracted text from the Phase 5
        pipeline. Deliberately not filtered by approval status — a
        student can ask their tutor about their own notes before a
        moderator has reviewed them; approval only gates whether other
        students can see the document in the public library."""
        result = await self.db.execute(
            select(DocumentAnalysis.document_id, DocumentAnalysis.extracted_text)
            .join(Document, Document.id == DocumentAnalysis.document_id)
            .where(Document.uploader_id == to_uuid(uploader_id))
            .where(DocumentAnalysis.extracted_text.isnot(None))
        )
        return [(str(row[0]), row[1]) for row in result.all()]

    async def list_extracted_texts_by_category(self, uploader_id: str, category: str) -> list[tuple[str, str]]:
        """Feeds mock-exam generation (Phase 11): every one of a
        student's own documents tagged with a given subject/category,
        so a mock-exam section can draw on all of a subject's uploaded
        material rather than a single document."""
        result = await self.db.execute(
            select(DocumentAnalysis.document_id, DocumentAnalysis.extracted_text)
            .join(Document, Document.id == DocumentAnalysis.document_id)
            .where(Document.uploader_id == to_uuid(uploader_id))
            .where(Document.category == category)
            .where(DocumentAnalysis.extracted_text.isnot(None))
        )
        return [(str(row[0]), row[1]) for row in result.all()]

    # --- Admin/moderation (Phase 16) ---

    async def get_by_id(self, document_id: str) -> Document | None:
        """Unscoped by uploader — for admin use only, gated by
        get_current_admin_user at the router layer."""
        result = await self.db.execute(select(Document).where(Document.id == to_uuid(document_id)))
        return result.scalar_one_or_none()

    async def list_for_review(self) -> list[Document]:
        result = await self.db.execute(
            select(Document)
            .where(Document.status.in_(["UnderReview", "NeedsRevision"]))
            .order_by(Document.created_at)
        )
        return list(result.scalars().all())

    async def get_analysis(self, document_id: str) -> DocumentAnalysis | None:
        result = await self.db.execute(
            select(DocumentAnalysis).where(DocumentAnalysis.document_id == to_uuid(document_id))
        )
        return result.scalar_one_or_none()

    async def list_validations(self, document_id: str) -> list[DocumentValidation]:
        result = await self.db.execute(
            select(DocumentValidation).where(DocumentValidation.document_id == to_uuid(document_id))
        )
        return list(result.scalars().all())

    async def get_exam_metadata(self, document_id: str) -> DocumentMetadataExam | None:
        result = await self.db.execute(
            select(DocumentMetadataExam).where(DocumentMetadataExam.document_id == to_uuid(document_id))
        )
        return result.scalar_one_or_none()

    async def count_approved_for_user(self, uploader_id: str) -> int:
        """Feeds Phase 15's credit-bonus trigger — this is the count
        that function was written and tested against, finally wired to
        something real."""
        result = await self.db.execute(
            select(Document)
            .where(Document.uploader_id == to_uuid(uploader_id))
            .where(Document.status == "Approved")
        )
        return len(result.scalars().all())

    async def count_by_status(self) -> dict[str, int]:
        result = await self.db.execute(select(Document.status))
        counts: dict[str, int] = {}
        for row in result.all():
            counts[row[0]] = counts.get(row[0], 0) + 1
        return counts
