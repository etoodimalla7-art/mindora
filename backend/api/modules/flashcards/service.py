from datetime import datetime, timezone

from api.core.errors import NotFoundError
from api.modules.flashcards.generation import generate_flashcards_from_text
from api.modules.flashcards.repository import FlashcardsRepository
from api.modules.flashcards.spaced_repetition import compute_next_due
from api.modules.flashcards.schemas import GenerateFlashcardsIn


def _as_aware_utc(dt: datetime) -> datetime:
    """SQLite (used in tests, and possible on some deployments) doesn't
    preserve timezone info on round-trip even for a `DateTime(timezone=
    True)` column — a naive value read back is implicitly UTC, since
    that's all this codebase ever writes. Comparing it against an aware
    `now` without this raises TypeError rather than silently misbehaving,
    which is how this got caught."""
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)


class FlashcardsService:
    def __init__(self, repo: FlashcardsRepository, documents_repo):
        self.repo = repo
        self.documents_repo = documents_repo  # for extracted text when generating from a document

    async def generate(self, owner_id: str, payload: GenerateFlashcardsIn):
        text = ""
        if payload.source_document_id:
            texts = await self.documents_repo.list_extracted_texts_for_user(owner_id)
            match = next((t for doc_id, t in texts if doc_id == payload.source_document_id), None)
            text = match or ""
        cards = generate_flashcards_from_text(text, payload.topic_title, payload.max_cards)
        return await self.repo.create_many(owner_id, payload.topic_title, payload.source_document_id, cards)

    async def list_due(self, owner_id: str, topic_title: str | None = None):
        flashcards = await self.repo.list_owned(owner_id, topic_title)
        if not flashcards:
            return []
        reviews = await self.repo.list_reviews_for_cards(owner_id, [str(f.id) for f in flashcards])
        latest_by_card: dict[str, object] = {}
        for review in reviews:  # ascending order -> last write wins = most recent
            latest_by_card[str(review.flashcard_id)] = review

        now = datetime.now(timezone.utc)
        due = []
        for card in flashcards:
            latest = latest_by_card.get(str(card.id))
            if latest is None or _as_aware_utc(latest.next_due_at) <= now:
                due.append(card)
        return due

    async def review(self, flashcard_id: str, owner_id: str, state: str):
        flashcard = await self.repo.get_owned(flashcard_id, owner_id)
        if not flashcard:
            raise NotFoundError("We couldn't find this flashcard.")
        reviews = await self.repo.list_reviews_for_cards(owner_id, [flashcard_id])
        consecutive_known = reviews[-1].consecutive_known if reviews else 0
        next_due_at, new_streak = compute_next_due(state, consecutive_known)
        return await self.repo.record_review(flashcard_id, owner_id, state, next_due_at, new_streak)
