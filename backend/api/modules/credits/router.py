from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.modules.credits.repository import CreditsRepository
from api.modules.credits.schemas import CreditBalanceOut, CreditTransactionOut, DownloadOut
from api.modules.credits.service import CreditsService
from api.modules.users.models import User

router = APIRouter(prefix="/credits", tags=["credits"])


def get_service(db: AsyncSession = Depends(get_db)) -> CreditsService:
    return CreditsService(CreditsRepository(db))


@router.get("/balance")
async def balance(
    current_user: User = Depends(get_current_user),
    service: CreditsService = Depends(get_service),
):
    bal = await service.get_balance(str(current_user.id))
    return envelope(data=CreditBalanceOut(balance=bal).model_dump())


@router.get("/history")
async def history(
    current_user: User = Depends(get_current_user),
    service: CreditsService = Depends(get_service),
):
    transactions = await service.list_history(str(current_user.id))
    return envelope(data=[CreditTransactionOut.model_validate(orm_to_dict(t)).model_dump() for t in transactions])


@router.get("/downloads")
async def downloads(
    current_user: User = Depends(get_current_user),
    service: CreditsService = Depends(get_service),
):
    items = await service.list_downloads(str(current_user.id))
    return envelope(data=[DownloadOut.model_validate(orm_to_dict(d)).model_dump() for d in items])
