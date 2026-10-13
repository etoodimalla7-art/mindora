"""Progress tracking model — per-subject and per-topic mastery."""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin


class TopicProgress(Base, UUIDMixin, TimestampMixin):
    """Rolling mastery per topic for a user."""

    __tablename__ = "topic_progress"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    subject: Mapped[str] = mapped_column(String(80), nullable=False)
    topic: Mapped[str] = mapped_column(String(160), nullable=False)

    mastery: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    confidence: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)

    questions_seen: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    questions_correct: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    minutes_studied: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    last_reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
