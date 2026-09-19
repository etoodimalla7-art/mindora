from datetime import datetime

from sqlalchemy import String, Integer, DateTime, JSON, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class MockExam(Base):
    __tablename__ = "mock_exams"

    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    subject_names: Mapped[list] = mapped_column(JSON, default=list)
    difficulty: Mapped[str] = mapped_column(String(20), default="medium")
    duration_minutes: Mapped[int] = mapped_column(Integer, default=60)
    status: Mapped[str] = mapped_column(String(20), default="active")


class MockExamSection(Base):
    """One quiz per subject in the exam — reuses the Phase 10 quiz
    engine's Quiz/Question tables rather than duplicating question
    storage, so the same generation, scoring, and correction logic
    applies to both a standalone quiz and a mock-exam section."""
    __tablename__ = "mock_exam_sections"

    mock_exam_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("mock_exams.id"), index=True)
    subject_name: Mapped[str] = mapped_column(String(255))
    quiz_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("quizzes.id"))


class MockExamAttempt(Base):
    __tablename__ = "mock_exam_attempts"

    mock_exam_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("mock_exams.id"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    score: Mapped[float] = mapped_column(Float)
    section_scores: Mapped[dict] = mapped_column(JSON, default=dict)
    answers: Mapped[dict] = mapped_column(JSON, default=dict)  # {question_id: chosen_answer}, so results can be rebuilt later
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
