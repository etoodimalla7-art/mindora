from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.subscriptions.models import Subscription


class SubscriptionsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_active(self, user_id: str) -> Subscription | None:
        now = datetime.now(timezone.utc)
        result = await self.db.execute(
            select(Subscription)
            .where(Subscription.user_id == to_uuid(user_id))
            .where(Subscription.status == "active")
            .where(Subscription.current_period_end >= now)
            .order_by(Subscription.current_period_end.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def create(
        self, user_id: str, plan_code: str, current_period_end: datetime, provider_reference: str | None,
    ) -> Subscription:
        subscription = Subscription(
            user_id=to_uuid(user_id), plan_code=plan_code, status="active",
            current_period_end=current_period_end, provider_reference=provider_reference,
        )
        self.db.add(subscription)
        await self.db.commit()
        await self.db.refresh(subscription)
        return subscription

    async def cancel_active(self, user_id: str) -> Subscription | None:
        subscription = await self.get_active(user_id)
        if subscription:
            subscription.status = "canceled"
            await self.db.commit()
            await self.db.refresh(subscription)
        return subscription
