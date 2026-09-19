from sqlalchemy import String, Boolean, Integer, Float, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base

DOCUMENT_STATUSES = (
    "Draft", "Uploading", "Processing", "UnderReview",
    "Approved", "Rejected", "NeedsRevision", "Archived", "Removed",
)


class Document(Base):
    __tablename__ = "documents"

    uploader_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    title: Mapped[str | None] = mapped_column(String(255), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    category: Mapped[str | None] = mapped_column(String(100), nullable=True)
    level: Mapped[str | None] = mapped_column(String(100), nullable=True)
    language: Mapped[str | None] = mapped_column(String(10), nullable=True)
    file_key: Mapped[str] = mapped_column(String(500))
    original_filename: Mapped[str] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(20), default="Draft")


class DocumentMetadataExam(Base):
    """Populated only when the contributor flags the document as an
    official examination paper (section 19)."""
    __tablename__ = "document_metadata"

    document_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("documents.id"), unique=True)
    is_exam: Mapped[bool] = mapped_column(Boolean, default=False)
    exam_system: Mapped[str | None] = mapped_column(String(100), nullable=True)
    exam_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    exam_level: Mapped[str | None] = mapped_column(String(100), nullable=True)
    exam_subject: Mapped[str | None] = mapped_column(String(255), nullable=True)
    exam_year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    exam_session: Mapped[str | None] = mapped_column(String(50), nullable=True)


class DocumentValidation(Base):
    """One row per automated check run during submission (section 18/22)."""
    __tablename__ = "document_validations"

    document_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("documents.id"), index=True)
    check_name: Mapped[str] = mapped_column(String(100))
    passed: Mapped[bool] = mapped_column(Boolean)
    detail: Mapped[str | None] = mapped_column(String(500), nullable=True)


class DocumentAnalysis(Base):
    """
    Filled in by the analysis pipeline (Phase 5) on every submit. A
    fresh row is upserted each time so re-submission after a revision
    always reflects the latest file/metadata.
    """
    __tablename__ = "document_analysis"

    document_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("documents.id"), unique=True)
    extracted_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    content_hash: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    page_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    detected_language: Mapped[str | None] = mapped_column(String(10), nullable=True)
    detected_subject: Mapped[str | None] = mapped_column(String(100), nullable=True)
    detected_level: Mapped[str | None] = mapped_column(String(100), nullable=True)
    quality_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    duplicate_of_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("documents.id"), nullable=True)
    similarity_score: Mapped[float | None] = mapped_column(Float, nullable=True)
