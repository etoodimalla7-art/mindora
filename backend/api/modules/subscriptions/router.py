from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.integrations.payment_provider import get_payment_provider
from api.modules.subscriptions.repository import SubscriptionsRepository
from api.modules.subscriptions.schemas import PlanOut, SubscribeIn, SubscriptionOut
from api.modules.subscriptions.service import SubscriptionsService
from api.modules.users.models import User

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


def get_service(db: AsyncSession = Depends(get_db)) -> SubscriptionsService:
    return SubscriptionsService(SubscriptionsRepository(db), get_payment_provider())


@router.get("/plans")
async def plans(service: SubscriptionsService = Depends(get_service)):
    return envelope(data=[PlanOut(**p).model_dump() for p in service.list_plans()])


@router.post("/subscribe")
async def subscribe(
    payload: SubscribeIn,
    current_user: User = Depends(get_current_user),
    service: SubscriptionsService = Depends(get_service),
):
    subscription = await service.subscribe(str(current_user.id), payload.plan_code)
    return envelope(data=SubscriptionOut.model_validate(subscription).model_dump())


@router.post("/cancel")
async def cancel(
    current_user: User = Depends(get_current_user),
    service: SubscriptionsService = Depends(get_service),
):
    subscription = await service.cancel(str(current_user.id))
    return envelope(data=SubscriptionOut.model_validate(subscription).model_dump())
