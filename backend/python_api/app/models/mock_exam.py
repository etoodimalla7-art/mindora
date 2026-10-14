"""Mock exam, questions, and answers."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDMixin

# Lifecycle
MOCK_STATUS_DRAFT = "draft"
MOCK_STATUS_READY = "ready"
MOCK_STATUS_IN_PROGRESS = "in_progress"
MOCK_STATUS_SUBMITTED = "submitted"
MOCK_STATUS_GRADED = "graded"
MOCK_STATUS_ABANDONED = "abandoned"

# Question types
QUESTION_MCQ = "mcq"           # multiple choice (single correct)
QUESTION_TRUE_FALSE = "true_false"
QUESTION_SHORT = "short_answer"


class MockExam(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "mock_exams"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    subject: Mapped[str] = mapped_column(String(80), nullable=False)
    academic_level: Mapped[str | None] = mapped_column(String(40), nullable=True)

    # Configuration
    question_count: Mapped[int] = mapped_column(Integer, nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    difficulty: Mapped[str] = mapped_column(
        String(20), default="medium", nullable=False
    )

    # Optional: restrict to specific documents
    source_document_ids: Mapped[list] = mapped_column(
        JSONB, default=list, nullable=False
    )

    # Lifecycle
    status: Mapped[str] = mapped_column(
        String(20), default=MOCK_STATUS_DRAFT, nullable=False, index=True
    )
    started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    submitted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    graded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Results
    score: Mapped[float | None] = mapped_column(Float, nullable=True)  # 0..100
    correct_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    wrong_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    skipped_count: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Feedback
    feedback_summary: Mapped[str | None] = mapped_column(Text, nullable=True)

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    questions: Mapped[list["MockQuestion"]] = relationship(
        back_populates="exam",
        cascade="all, delete-orphan",
        order_by="MockQuestion.position",
        lazy="selectin",
    )


class MockQuestion(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "mock_questions"

    exam_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("mock_exams.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )

    position: Mapped[int] = mapped_column(Integer, nullable=False)
    question_type: Mapped[str] = mapped_column(String(20), nullable=False)
    prompt: Mapped[str] = mapped_column(Text, nullable=False)

    # For MCQ: list of {"label": "A", "text": "..."}
    options: Mapped[list] = mapped_column(JSONB, default=list, nullable=False)

    # The correct answer (letter for MCQ, "true"/"false", or free text)
    correct_answer: Mapped[str] = mapped_column(Text, nullable=False)

    # Explanation shown after submission
    explanation: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Difficulty: easy | medium | hard
    difficulty: Mapped[str] = mapped_column(
        String(20), default="medium", nullable=False
    )

    # Points awarded if correct
    points: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    # Free-form (source document reference, topic tags...)
    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    exam: Mapped[MockExam] = relationship(back_populates="questions")
    answers: Mapped[list["MockAnswer"]] = relationship(
        back_populates="question",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class MockAnswer(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "mock_answers"

    exam_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("mock_exams.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    question_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("mock_questions.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )

    # What the student answered
    user_answer: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Graded
    is_correct: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    points_awarded: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Time spent in seconds (optional)
    time_spent_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # AI feedback for short-answer
    ai_feedback: Mapped[str | None] = mapped_column(Text, nullable=True)

    question: Mapped[MockQuestion] = relationship(back_populates="answers")
