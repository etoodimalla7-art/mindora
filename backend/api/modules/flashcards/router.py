from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.modules.documents.repository import DocumentsRepository
from api.modules.flashcards.repository import FlashcardsRepository
from api.modules.flashcards.schemas import FlashcardOut, GenerateFlashcardsIn, ReviewFlashcardIn
from api.modules.flashcards.service import FlashcardsService
from api.modules.users.models import User

router = APIRouter(prefix="/flashcards", tags=["flashcards"])


def get_service(db: AsyncSession = Depends(get_db)) -> FlashcardsService:
    return FlashcardsService(FlashcardsRepository(db), DocumentsRepository(db))


@router.post("/generate")
async def generate(
    payload: GenerateFlashcardsIn,
    current_user: User = Depends(get_current_user),
    service: FlashcardsService = Depends(get_service),
):
    cards = await service.generate(str(current_user.id), payload)
    return envelope(data=[FlashcardOut.model_validate(orm_to_dict(c)).model_dump() for c in cards])


@router.get("")
async def list_due(
    topic: str | None = Query(default=None),
    current_user: User = Depends(get_current_user),
    service: FlashcardsService = Depends(get_service),
):
    cards = await service.list_due(str(current_user.id), topic)
    return envelope(data=[FlashcardOut.model_validate(orm_to_dict(c)).model_dump() for c in cards])


@router.post("/{flashcard_id}/review")
async def review(
    flashcard_id: str,
    payload: ReviewFlashcardIn,
    current_user: User = Depends(get_current_user),
    service: FlashcardsService = Depends(get_service),
):
    result = await service.review(flashcard_id, str(current_user.id), payload.state)
    return envelope(data={"next_due_at": result.next_due_at.isoformat(), "consecutive_known": result.consecutive_known})
