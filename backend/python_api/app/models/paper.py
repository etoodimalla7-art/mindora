"""Paper (past exam) model — admin-curated library."""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDMixin

# Statuses
PAPER_STATUS_DRAFT = "draft"
PAPER_STATUS_PUBLISHED = "published"
PAPER_STATUS_ARCHIVED = "archived"

# Allowed MIME types / extensions
ALLOWED_PAPER_MIME_TYPES = (
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
)
ALLOWED_PAPER_EXTENSIONS = (".pdf", ".doc", ".docx")
MAX_PAPER_SIZE_BYTES = 25 * 1024 * 1024  # 25 MB


class Paper(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    """A past exam / subject paper managed by admins."""

    __tablename__ = "papers"

    # Uploader (always an admin)
    uploader_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )

    # Content metadata
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    subject: Mapped[str] = mapped_column(String(80), nullable=False, index=True)
    exam_system: Mapped[str] = mapped_column(String(40), nullable=False, index=True)
    exam_level: Mapped[str] = mapped_column(String(40), nullable=False, index=True)
    exam_year: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    language: Mapped[str] = mapped_column(String(8), default="fr", nullable=False)

    # File (stored as bytes — same as Document for now, will move to R2 later)
    file_data: Mapped[bytes] = mapped_column(nullable=False)
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_size: Mapped[int] = mapped_column(Integer, nullable=False)
    mime_type: Mapped[str] = mapped_column(String(80), nullable=False)

    # Status & stats
    status: Mapped[str] = mapped_column(
        String(20), default=PAPER_STATUS_PUBLISHED, nullable=False, index=True
    )
    download_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Free-form metadata
    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
