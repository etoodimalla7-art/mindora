"""Flashcard service — CRUD + SM-2 review + due cards."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.models.flashcard import Flashcard, FlashcardDeck
from app.schemas.flashcard import (
    DeckOut,
    FlashcardOut,
    ReviewCardResponse,
)
from app.services.sm2 import update_sm2

logger = logging.getLogger(__name__)


class FlashcardService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Decks ----------

    async def list_decks(self, user_id: uuid.UUID) -> list[DeckOut]:
        stmt = (
            select(FlashcardDeck)
            .where(
                FlashcardDeck.user_id == user_id,
                FlashcardDeck.deleted_at.is_(None),
            )
            .order_by(FlashcardDeck.created_at.desc())
        )
        decks = (await self.session.execute(stmt)).scalars().all()

        now = datetime.now(timezone.utc)
        result: list[DeckOut] = []
        for d in decks:
            card_count = await self._count_cards(d.id)
            due_count = await self._count_due(d.id, now)
            result.append(
                DeckOut(
                    id=d.id,
                    title=d.title,
                    description=d.description,
                    subject=d.subject,
                    card_count=card_count,
                    due_count=due_count,
                    created_at=d.created_at,
                )
            )
        return result

    async def create_deck(
        self, user_id: uuid.UUID, title: str, description: str | None, subject: str | None
    ) -> DeckOut:
        deck = FlashcardDeck(
            user_id=user_id, title=title, description=description, subject=subject
        )
        self.session.add(deck)
        await self.session.commit()
        await self.session.refresh(deck)
        return DeckOut(
            id=deck.id,
            title=deck.title,
            description=deck.description,
            subject=deck.subject,
            card_count=0,
            due_count=0,
            created_at=deck.created_at,
        )

    async def get_deck(self, user_id: uuid.UUID, deck_id: uuid.UUID) -> FlashcardDeck:
        stmt = select(FlashcardDeck).where(
            FlashcardDeck.id == deck_id,
            FlashcardDeck.user_id == user_id,
            FlashcardDeck.deleted_at.is_(None),
        )
        deck = (await self.session.execute(stmt)).scalar_one_or_none()
        if not deck:
            raise NotFoundError("Deck not found.")
        return deck

    async def delete_deck(self, user_id: uuid.UUID, deck_id: uuid.UUID) -> None:
        deck = await self.get_deck(user_id, deck_id)
        await self.session.delete(deck)
        await self.session.commit()

    # ---------- Cards ----------

    async def add_card(
        self, user_id: uuid.UUID, deck_id: uuid.UUID, front: str, back: str
    ) -> FlashcardOut:
        deck = await self.get_deck(user_id, deck_id)
        card = Flashcard(deck_id=deck.id, front=front, back=back)
        self.session.add(card)
        await self.session.commit()
        await self.session.refresh(card)
        return FlashcardOut.model_validate(card)

    async def get_due_cards(
        self, user_id: uuid.UUID, deck_id: uuid.UUID, limit: int = 20
    ) -> list[FlashcardOut]:
        await self.get_deck(user_id, deck_id)
        now = datetime.now(timezone.utc)
        stmt = (
            select(Flashcard)
            .where(
                Flashcard.deck_id == deck_id,
                Flashcard.deleted_at.is_(None),
                (Flashcard.next_review_at.is_(None))
                | (Flashcard.next_review_at <= now),
            )
            .order_by(Flashcard.next_review_at.asc().nullsfirst())
            .limit(limit)
        )
        cards = (await self.session.execute(stmt)).scalars().all()
        return [FlashcardOut.model_validate(c) for c in cards]

    async def review_card(
        self, user_id: uuid.UUID, card_id: uuid.UUID, quality: int
    ) -> ReviewCardResponse:
        stmt = select(Flashcard).where(
            Flashcard.id == card_id,
            Flashcard.deleted_at.is_(None),
        )
        card = (await self.session.execute(stmt)).scalar_one_or_none()
        if not card:
            raise NotFoundError("Card not found.")

        # Ensure ownership
        await self.get_deck(user_id, card.deck_id)

        result = update_sm2(
            current_ease=card.ease_factor,
            current_interval=card.interval_days,
            current_repetitions=card.repetitions,
            quality=quality,
        )
        card.ease_factor = result.ease_factor
        card.interval_days = result.interval_days
        card.repetitions = result.repetitions
        card.next_review_at = result.next_review_at
        card.last_reviewed_at = datetime.now(timezone.utc)
        await self.session.commit()

        return ReviewCardResponse(
            card_id=card.id,
            ease_factor=card.ease_factor,
            interval_days=card.interval_days,
            repetitions=card.repetitions,
            next_review_at=card.next_review_at or datetime.now(timezone.utc),
        )

    # ---------- Helpers ----------

    async def _count_cards(self, deck_id: uuid.UUID) -> int:
        stmt = select(func.count(Flashcard.id)).where(
            Flashcard.deck_id == deck_id,
            Flashcard.deleted_at.is_(None),
        )
        return int((await self.session.execute(stmt)).scalar() or 0)

    async def _count_due(self, deck_id: uuid.UUID, now: datetime) -> int:
        stmt = select(func.count(Flashcard.id)).where(
            Flashcard.deck_id == deck_id,
            Flashcard.deleted_at.is_(None),
            (Flashcard.next_review_at.is_(None))
            | (Flashcard.next_review_at <= now),
        )
        return int((await self.session.execute(stmt)).scalar() or 0)
