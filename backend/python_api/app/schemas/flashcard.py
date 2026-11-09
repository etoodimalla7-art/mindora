"""Flashcard & Deck DTOs."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


# ---------- Deck ----------

class DeckCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    subject: str | None = None


class DeckOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    description: str | None
    subject: str | None
    card_count: int = 0
    due_count: int = 0
    created_at: datetime


class DeckDetail(DeckOut):
    cards: list["FlashcardOut"] = []


# ---------- Card ----------

class FlashcardCreate(BaseModel):
    front: str = Field(min_length=1)
    back: str = Field(min_length=1)


class FlashcardOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    deck_id: uuid.UUID
    front: str
    back: str
    ease_factor: float
    interval_days: int
    repetitions: int
    next_review_at: datetime | None
    last_reviewed_at: datetime | None
    created_at: datetime


# ---------- Review ----------

class ReviewCardRequest(BaseModel):
    """Submit a review with quality 0..5."""
    quality: int = Field(ge=0, le=5)


class ReviewCardResponse(BaseModel):
    card_id: uuid.UUID
    ease_factor: float
    interval_days: int
    repetitions: int
    next_review_at: datetime


# ---------- AI generation ----------

class GenerateDeckRequest(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    document_id: uuid.UUID | None = None
    count: int = Field(default=10, ge=1, le=30)


DeckDetail.model_rebuild()
