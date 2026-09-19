from datetime import datetime

from sqlalchemy import String, Text, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class Flashcard(Base):
    __tablename__ = "flashcards"

    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    topic_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("topics.id"), nullable=True)
    topic_title: Mapped[str] = mapped_column(String(255))
    front: Mapped[str] = mapped_column(Text)
    back: Mapped[str] = mapped_column(Text)
    card_type: Mapped[str] = mapped_column(String(30), default="concept")
    source_document_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("documents.id"), nullable=True)


class FlashcardReview(Base):
    """One row per review event (section 38's known/uncertain/forgotten
    tracking). Kept as a history rather than overwriting current state,
    so future analytics (section 41) can see review frequency over time."""
    __tablename__ = "flashcard_reviews"

    flashcard_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("flashcards.id"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    state: Mapped[str] = mapped_column(String(20))  # known | uncertain | forgotten
    consecutive_known: Mapped[int] = mapped_column(Integer, default=0)
    reviewed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    next_due_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
