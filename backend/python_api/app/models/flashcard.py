"""Flashcard and Deck models with SM-2 spaced repetition fields."""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDMixin


class FlashcardDeck(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    """A collection of flashcards (e.g., 'Derivatives', 'French Revolution')."""

    __tablename__ = "flashcard_decks"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    subject: Mapped[str | None] = mapped_column(String(80), nullable=True)
    
    # Optional: link to a document (if deck was generated from a PDF)
    document_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("documents.id", ondelete="SET NULL"), nullable=True
    )

    cards: Mapped[list["Flashcard"]] = relationship(
        back_populates="deck", cascade="all, delete-orphan"
    )


class Flashcard(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    """A single flashcard with SM-2 spaced repetition tracking."""

    __tablename__ = "flashcards"

    deck_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("flashcard_decks.id", ondelete="CASCADE"), index=True, nullable=False
    )

    front: Mapped[str] = mapped_column(Text, nullable=False)
    back: Mapped[str] = mapped_column(Text, nullable=False)
    
    # SM-2 Algorithm fields
    ease_factor: Mapped[float] = mapped_column(Float, default=2.5, nullable=False)
    interval_days: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    repetitions: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    
    # Scheduling
    next_review_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    last_reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    deck: Mapped[FlashcardDeck] = relationship(back_populates="cards")
