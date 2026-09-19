from datetime import datetime

from sqlalchemy import String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class StudySession(Base):
    """
    subject_id/topic_id (Phase 7) link to the real catalog when a match
    exists; subject_name/topic_title stay as a denormalized display
    cache so the UI never needs an extra join, and so a session created
    before a subject had catalog topics (or a "General review" fallback
    session) still displays sensibly.
    """
    __tablename__ = "study_sessions"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    plan_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("study_plans.id"), nullable=True)
    subject_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("subjects.id"), nullable=True)
    topic_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("topics.id"), nullable=True)
    subject_name: Mapped[str] = mapped_column(String(255))
    topic_title: Mapped[str] = mapped_column(String(255))
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    duration_minutes: Mapped[int] = mapped_column(Integer, default=30)
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending|completed|missed|rescheduled
