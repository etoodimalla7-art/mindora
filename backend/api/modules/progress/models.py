from sqlalchemy import String, Float, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
import uuid

from api.core.db import Base


class Progress(Base):
    __tablename__ = "progress"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    subject_name: Mapped[str] = mapped_column(String(255))
    mastery_score: Mapped[float] = mapped_column(Float, default=0.0)  # 0-100
    last_studied_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class ReadinessScore(Base):
    __tablename__ = "readiness_scores"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    target_exam_name: Mapped[str] = mapped_column(String(255))
    knowledge: Mapped[float] = mapped_column(Float, default=0.0)
    practice: Mapped[float] = mapped_column(Float, default=0.0)
    retention: Mapped[float] = mapped_column(Float, default=0.0)
    past_papers: Mapped[float] = mapped_column(Float, default=0.0)
    weak_topics: Mapped[float] = mapped_column(Float, default=0.0)
    consistency: Mapped[float] = mapped_column(Float, default=0.0)
    overall: Mapped[float] = mapped_column(Float, default=0.0)
    computed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
