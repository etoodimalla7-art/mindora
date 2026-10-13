"""Document, analysis, and moderation models."""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    LargeBinary,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDMixin

# Document lifecycle states.
DOC_STATUS_DRAFT = "draft"
DOC_STATUS_UPLOADING = "uploading"
DOC_STATUS_PROCESSING = "processing"
DOC_STATUS_UNDER_REVIEW = "under_review"
DOC_STATUS_APPROVED = "approved"
DOC_STATUS_REJECTED = "rejected"
DOC_STATUS_NEEDS_REVISION = "needs_revision"
DOC_STATUS_ARCHIVED = "archived"
DOC_STATUS_REMOVED = "removed"


class Document(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    """An uploaded educational document."""

    __tablename__ = "documents"

    owner_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    # Metadata declared by the contributor.
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str | None] = mapped_column(String(80), nullable=True)
    academic_level: Mapped[str | None] = mapped_column(String(40), nullable=True)
    language: Mapped[str] = mapped_column(String(8), default="en", nullable=False)

    # Exam-specific metadata (nullable for non-exam documents).
    is_exam_related: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    exam_system: Mapped[str | None] = mapped_column(String(40), nullable=True)
    exam_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    exam_year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    exam_session: Mapped[str | None] = mapped_column(String(40), nullable=True)
    document_type: Mapped[str | None] = mapped_column(String(60), nullable=True)

    # Raw bytes are stored here in Phase 6 (BYTEA). Phase 16 will migrate
    # to object storage and only keep the object key.
    content: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)
    original_filename: Mapped[str] = mapped_column(String(255), nullable=False)
    mime_type: Mapped[str] = mapped_column(String(120), nullable=False)
    size_bytes: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    page_count: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Hash of the raw bytes and of the extracted text — for dedup.
    content_hash: Mapped[str | None] = mapped_column(String(64), index=True, nullable=True)
    text_hash: Mapped[str | None] = mapped_column(String(64), index=True, nullable=True)

    # Extracted plain text (may be large).
    extracted_text: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Lifecycle.
    status: Mapped[str] = mapped_column(
        String(24), default=DOC_STATUS_DRAFT, nullable=False, index=True
    )
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    moderation_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Aggregate signals.
    download_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    quality_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    # Free-form extras (subject_tags, ai_provenance, detector_confidences...).
    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    analysis: Mapped["DocumentAnalysis"] = relationship(
        back_populates="document",
        uselist=False,
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    duplicates: Mapped[list["DocumentDuplicate"]] = relationship(
        back_populates="document",
        cascade="all, delete-orphan",
        lazy="selectin",
        foreign_keys="DocumentDuplicate.document_id",
    )


class DocumentAnalysis(Base, UUIDMixin, TimestampMixin):
    """AI-derived facts about a document."""

    __tablename__ = "document_analyses"

    document_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("documents.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )

    detected_language: Mapped[str | None] = mapped_column(String(8), nullable=True)
    language_confidence: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    detected_subject: Mapped[str | None] = mapped_column(String(80), nullable=True)
    subject_confidence: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    detected_level: Mapped[str | None] = mapped_column(String(40), nullable=True)
    level_confidence: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    detected_doc_type: Mapped[str | None] = mapped_column(String(60), nullable=True)
    doc_type_confidence: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    is_spam: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_inappropriate: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    contains_pii: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    quality_score: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    keywords: Mapped[list] = mapped_column(JSONB, default=list, nullable=False)
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Raw provider response, for auditing.
    raw_response: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    document: Mapped[Document] = relationship(back_populates="analysis")


class DocumentDuplicate(Base, UUIDMixin, TimestampMixin):
    """Records near/exact duplicates for moderation."""

    __tablename__ = "document_duplicates"

    document_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("documents.id", ondelete="CASCADE"), index=True, nullable=False
    )
    candidate_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("documents.id", ondelete="CASCADE"), index=True, nullable=False
    )

    similarity: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    matched_on: Mapped[str] = mapped_column(String(24), default="hash", nullable=False)
    reviewed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    verdict: Mapped[str | None] = mapped_column(String(24), nullable=True)

    document: Mapped[Document] = relationship(
        back_populates="duplicates", foreign_keys=[document_id]
    )


class DescriptionValidation(Base, UUIDMixin, TimestampMixin):
    """Audit trail of the 500-word description validation."""

    __tablename__ = "description_validations"

    document_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("documents.id", ondelete="CASCADE"), index=True, nullable=False
    )

    word_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    unique_word_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    repetition_ratio: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    passed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    failure_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
