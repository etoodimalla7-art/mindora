from datetime import datetime

from sqlalchemy import String, Text, Float, DateTime, JSON, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class Quiz(Base):
    __tablename__ = "quizzes"

    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    topic_title: Mapped[str] = mapped_column(String(255))
    difficulty: Mapped[str] = mapped_column(String(20), default="medium")
    source_document_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("documents.id"), nullable=True)


class Question(Base):
    __tablename__ = "questions"

    quiz_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("quizzes.id"), index=True)
    q_type: Mapped[str] = mapped_column(String(30))  # multiple_choice | true_false
    prompt: Mapped[str] = mapped_column(Text)
    choices: Mapped[list] = mapped_column(JSON, default=list)
    correct_answer: Mapped[str] = mapped_column(Text)


class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    quiz_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("quizzes.id"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    score: Mapped[float] = mapped_column(Float)  # 0-100
    answers: Mapped[dict] = mapped_column(JSON, default=dict)  # {question_id: chosen_answer}
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
