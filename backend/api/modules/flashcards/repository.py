from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.flashcards.models import Flashcard, FlashcardReview


class FlashcardsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_many(
        self, owner_id: str, topic_title: str, source_document_id: str | None, cards: list[dict]
    ) -> list[Flashcard]:
        flashcards = [
            Flashcard(
                owner_id=to_uuid(owner_id),
                topic_title=topic_title,
                front=c["front"],
                back=c["back"],
                card_type=c.get("type", "concept"),
                source_document_id=to_uuid(source_document_id) if source_document_id else None,
            )
            for c in cards
        ]
        self.db.add_all(flashcards)
        await self.db.commit()
        for card in flashcards:
            await self.db.refresh(card)
        return flashcards

    async def list_owned(self, owner_id: str, topic_title: str | None = None) -> list[Flashcard]:
        query = select(Flashcard).where(Flashcard.owner_id == to_uuid(owner_id))
        if topic_title:
            query = query.where(Flashcard.topic_title == topic_title)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_owned(self, flashcard_id: str, owner_id: str) -> Flashcard | None:
        result = await self.db.execute(
            select(Flashcard)
            .where(Flashcard.id == to_uuid(flashcard_id))
            .where(Flashcard.owner_id == to_uuid(owner_id))
        )
        return result.scalar_one_or_none()

    async def list_reviews_for_cards(self, user_id: str, flashcard_ids: list[str]) -> list[FlashcardReview]:
        """Ascending by reviewed_at, so the LAST entry per flashcard_id
        in this list is that card's most recent review — small student-
        scale card counts make an in-Python latest-per-card pass simpler
        and just as correct as a SQL window function here."""
        if not flashcard_ids:
            return []
        result = await self.db.execute(
            select(FlashcardReview)
            .where(FlashcardReview.user_id == to_uuid(user_id))
            .where(FlashcardReview.flashcard_id.in_([to_uuid(i) for i in flashcard_ids]))
            .order_by(FlashcardReview.reviewed_at)
        )
        return list(result.scalars().all())

    async def record_review(
        self, flashcard_id: str, user_id: str, state: str, next_due_at: datetime, consecutive_known: int
    ) -> FlashcardReview:
        review = FlashcardReview(
            flashcard_id=to_uuid(flashcard_id),
            user_id=to_uuid(user_id),
            state=state,
            consecutive_known=consecutive_known,
            reviewed_at=datetime.now(timezone.utc),
            next_due_at=next_due_at,
        )
        self.db.add(review)
        await self.db.commit()
        await self.db.refresh(review)
        return review

    async def list_reviews_with_topic_for_user(self, owner_id: str) -> list[tuple[str, str]]:
        """Returns (topic_title, state) for every flashcard review this
        user has made — feeds progress analytics (Phase 12)."""
        result = await self.db.execute(
            select(Flashcard.topic_title, FlashcardReview.state)
            .join(FlashcardReview, FlashcardReview.flashcard_id == Flashcard.id)
            .where(FlashcardReview.user_id == to_uuid(owner_id))
        )
        return [(row[0], row[1]) for row in result.all()]
