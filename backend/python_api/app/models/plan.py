"""Study plan and session models."""
from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDMixin


class StudyPlan(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    """A study roadmap for an exam, a subject, or a university course."""

    __tablename__ = "study_plans"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    plan_type: Mapped[str] = mapped_column(String(16), nullable=False)

    title: Mapped[str] = mapped_column(String(160), nullable=False)
    subject: Mapped[str | None] = mapped_column(String(80), nullable=True)

    exam_system: Mapped[str | None] = mapped_column(String(32), nullable=True)
    exam_level: Mapped[str | None] = mapped_column(String(32), nullable=True)
    exam_name: Mapped[str | None] = mapped_column(String(120), nullable=True)

    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    target_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    daily_minutes: Mapped[int] = mapped_column(Integer, default=60, nullable=False)

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    sessions: Mapped[list["StudySession"]] = relationship(
        back_populates="plan",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class StudySession(Base, UUIDMixin, TimestampMixin):
    """A single scheduled or completed study session."""

    __tablename__ = "study_sessions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    plan_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("study_plans.id", ondelete="CASCADE"), index=True, nullable=True
    )

    title: Mapped[str] = mapped_column(String(160), nullable=False)
    subject: Mapped[str | None] = mapped_column(String(80), nullable=True)
    topic: Mapped[str | None] = mapped_column(String(160), nullable=True)
    objective: Mapped[str | None] = mapped_column(Text, nullable=True)

    scheduled_for: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, default=45, nullable=False)

    status: Mapped[str] = mapped_column(String(16), default="scheduled", nullable=False)

    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    plan: Mapped[StudyPlan | None] = relationship(back_populates="sessions")
