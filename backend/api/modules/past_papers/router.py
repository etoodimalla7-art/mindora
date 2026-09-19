from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.modules.credits.repository import CreditsRepository
from api.modules.credits.schemas import DownloadOut
from api.modules.credits.service import CreditsService
from api.modules.past_papers.repository import PastPapersRepository
from api.modules.past_papers.schemas import PastPaperFiltersOut
from api.modules.past_papers.service import PastPapersService
from api.modules.subscriptions.repository import SubscriptionsRepository
from api.modules.subscriptions.service import SubscriptionsService
from api.integrations.payment_provider import get_payment_provider
from api.modules.users.models import User

router = APIRouter(prefix="/past-papers", tags=["past-papers"])


def get_service(db: AsyncSession = Depends(get_db)) -> PastPapersService:
    return PastPapersService(PastPapersRepository(db))


def get_credits_service(db: AsyncSession = Depends(get_db)) -> CreditsService:
    return CreditsService(CreditsRepository(db))


def get_subscriptions_service(db: AsyncSession = Depends(get_db)) -> SubscriptionsService:
    return SubscriptionsService(SubscriptionsRepository(db), get_payment_provider())


@router.get("")
async def search(
    country: str | None = Query(default=None),
    system: str | None = Query(default=None),
    level: str | None = Query(default=None),
    subject: str | None = Query(default=None),
    year: int | None = Query(default=None),
    q: str | None = Query(default=None, max_length=200),
    current_user: User = Depends(get_current_user),
    service: PastPapersService = Depends(get_service),
):
    results = await service.search(
        str(current_user.id),
        country=country, system=system, level=level,
        subject_name=subject, year=year, query_text=q,
    )
    return envelope(data=[r.model_dump() for r in results])


@router.get("/filters")
async def filters(
    current_user: User = Depends(get_current_user),
    service: PastPapersService = Depends(get_service),
):
    data = await service.get_filters()
    return envelope(data=PastPaperFiltersOut(**data).model_dump())


@router.get("/bookmarks")
async def list_bookmarks(
    current_user: User = Depends(get_current_user),
    service: PastPapersService = Depends(get_service),
):
    results = await service.list_bookmarked(str(current_user.id))
    return envelope(data=[r.model_dump() for r in results])


@router.post("/{past_paper_id}/bookmark")
async def bookmark(
    past_paper_id: str,
    current_user: User = Depends(get_current_user),
    service: PastPapersService = Depends(get_service),
):
    await service.bookmark(str(current_user.id), past_paper_id)
    return envelope(data={"success": True})


@router.delete("/{past_paper_id}/bookmark")
async def unbookmark(
    past_paper_id: str,
    current_user: User = Depends(get_current_user),
    service: PastPapersService = Depends(get_service),
):
    await service.unbookmark(str(current_user.id), past_paper_id)
    return envelope(data={"success": True})


@router.post("/{past_paper_id}/download")
async def download(
    past_paper_id: str,
    current_user: User = Depends(get_current_user),
    service: PastPapersService = Depends(get_service),
    credits_service: CreditsService = Depends(get_credits_service),
    subscriptions_service: SubscriptionsService = Depends(get_subscriptions_service),
):
    has_subscription = await subscriptions_service.has_active_subscription(str(current_user.id))
    row = await service.download(str(current_user.id), past_paper_id, credits_service, has_subscription)
    return envelope(data={
        "document_id": str(row.document_id) if row.document_id else None,
        "available": row.document_id is not None,
    })
