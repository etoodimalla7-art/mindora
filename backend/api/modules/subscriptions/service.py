from datetime import datetime, timedelta, timezone

from api.core.errors import ValidationFailedError
from api.modules.subscriptions.plans import get_plans
from api.modules.subscriptions.repository import SubscriptionsRepository


class SubscriptionsService:
    def __init__(self, repo: SubscriptionsRepository, payment_provider):
        self.repo = repo
        self.payment_provider = payment_provider

    def list_plans(self) -> list[dict]:
        return get_plans()

    async def has_active_subscription(self, user_id: str) -> bool:
        return await self.repo.get_active(user_id) is not None

    async def subscribe(self, user_id: str, plan_code: str):
        plan = next((p for p in get_plans() if p["code"] == plan_code), None)
        if not plan:
            raise ValidationFailedError("That plan doesn't exist.")

        charge = await self.payment_provider.charge(
            user_id, plan["amount_minor_units"], plan["currency"], plan["name"],
        )
        if not charge.success:
            raise ValidationFailedError(charge.error_message or "Payment failed. Please try again.")

        period_end = datetime.now(timezone.utc) + (
            timedelta(days=365) if plan["interval"] == "year" else timedelta(days=30)
        )
        return await self.repo.create(user_id, plan_code, period_end, charge.provider_reference)

    async def cancel(self, user_id: str):
        subscription = await self.repo.cancel_active(user_id)
        if not subscription:
            raise ValidationFailedError("You don't have an active subscription to cancel.")
        return subscription
