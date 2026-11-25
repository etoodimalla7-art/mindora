"""Subscription orchestration service."""
from __future__ import annotations

import logging
import secrets
import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.errors import ConflictError, NotFoundError, ValidationError
from app.integrations.payments.factory import get_payment_provider
from app.integrations.payments.provider import CheckoutRequest, WebhookEvent
from app.models.subscription import (
    CYCLE_MONTHLY,
    CYCLE_QUARTERLY,
    CYCLE_YEARLY,
    PAY_STATUS_FAILED,
    PAY_STATUS_PENDING,
    PAY_STATUS_SUCCEEDED,
    SUB_STATUS_ACTIVE,
    SUB_STATUS_CANCELLED,
    SUB_STATUS_EXPIRED,
    Payment,
    Plan,
    Subscription,
)
from app.repositories.subscription_repo import SubscriptionRepository
from app.schemas.subscription import (
    CheckoutResponseSchema,
    ConfirmResponse,
    PaymentOut,
    PlanOut,
    SubscriptionDetail,
    SubscriptionOut,
)

logger = logging.getLogger(__name__)

_CYCLE_DAYS = {
    CYCLE_MONTHLY: 30,
    CYCLE_QUARTERLY: 90,
    CYCLE_YEARLY: 365,
}


class SubscriptionService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.repo = SubscriptionRepository(session)

    # ---------- Plans ----------

    async def list_plans(self) -> list[PlanOut]:
        plans = await self.repo.list_active_plans()
        return [PlanOut.model_validate(p) for p in plans]

    # ---------- Subscription read ----------

    async def get_active(
        self, user_id: uuid.UUID
    ) -> SubscriptionDetail | None:
        sub = await self.repo.get_active_for_user(user_id)
        if not sub:
            return None
        return self._to_detail(sub)

    async def list_subscriptions(
        self, user_id: uuid.UUID
    ) -> list[SubscriptionOut]:
        subs = await self.repo.list_for_user(user_id)
        return [SubscriptionOut.model_validate(s) for s in subs]

    async def list_payments(self, user_id: uuid.UUID) -> list[PaymentOut]:
        payments = await self.repo.list_payments_for_user(user_id)
        return [PaymentOut.model_validate(p) for p in payments]

    # ---------- Checkout ----------

    async def start_checkout(
        self, user_id: uuid.UUID, plan_code: str, user_email: str, user_name: str
    ) -> CheckoutResponseSchema:
        plan = await self.repo.get_plan_by_code(plan_code)
        if not plan or not plan.is_active:
            raise NotFoundError("Plan not found or inactive.")

        # If the user already has an active subscription, disallow a new one.
        existing = await self.repo.get_active_for_user(user_id)
        if existing:
            raise ConflictError(
                "You already have an active subscription. "
                "Cancel it before subscribing to another plan."
            )

        # Create a pending subscription + a pending payment.
        sub = Subscription(
            user_id=user_id,
            plan_id=plan.id,
            status="pending",
            provider=settings.PAYMENT_PROVIDER,
        )
        await self.repo.create_subscription(sub)

        reference = f"MND-{uuid.uuid4().hex[:14].upper()}"
        payment = Payment(
            user_id=user_id,
            subscription_id=sub.id,
            plan_id=plan.id,
            status=PAY_STATUS_PENDING,
            amount_minor=plan.amount_minor,
            currency=plan.currency,
            reference=reference,
            provider=settings.PAYMENT_PROVIDER,
            redirect_url=settings.PAYMENT_REDIRECT_SUCCESS_URL,
        )
        await self.repo.create_payment(payment)
        await self.repo.commit()

        # Ask the provider to create a checkout session.
        provider = get_payment_provider()
        try:
            checkout = await provider.create_checkout(
                CheckoutRequest(
                    reference=reference,
                    amount_minor=plan.amount_minor,
                    currency=plan.currency,
                    customer_email=user_email,
                    customer_name=user_name,
                    redirect_url=settings.PAYMENT_REDIRECT_SUCCESS_URL,
                    description=f"MINDORA {plan.name}",
                    metadata={"plan_code": plan.code, "user_id": str(user_id)},
                )
            )
        except Exception as exc:  # noqa: BLE001
            logger.error("checkout_provider_failed ref=%s error=%s", reference, exc)
            payment.status = PAY_STATUS_FAILED
            payment.failure_reason = str(exc)[:300]
            await self.repo.commit()
            raise

        # Save provider reference.
        payment.provider_reference = checkout.provider_reference
        await self.repo.commit()
        await self.repo.refresh(payment)

        return CheckoutResponseSchema(
            payment=PaymentOut.model_validate(payment),
            checkout_url=checkout.checkout_url,
            provider=checkout.provider,
        )

    # ---------- Confirm (called by the frontend after returning) ----------

    async def confirm_payment(
        self, user_id: uuid.UUID, reference: str
    ) -> ConfirmResponse:
        payment = await self.repo.get_payment_by_reference(reference)
        if not payment:
            raise NotFoundError("Payment not found.")
        if payment.user_id != user_id:
            raise NotFoundError("Payment not found.")

        if payment.status == PAY_STATUS_SUCCEEDED:
            # Idempotent.
            sub = None
            if payment.subscription_id:
                sub_row = await self.repo.get_subscription(
                    payment.subscription_id, user_id
                )
                sub = self._to_detail(sub_row) if sub_row else None
            return ConfirmResponse(
                payment=PaymentOut.model_validate(payment),
                subscription=sub,
                status=payment.status,
                message="Payment was already confirmed.",
            )

        # Ask the provider to verify the payment status.
        provider = get_payment_provider()
        event = await provider.verify_payment(reference)

        return await self._apply_event(event, payment=payment)

    # ---------- Webhook ----------

    async def handle_webhook_event(self, event: WebhookEvent) -> None:
        payment = await self.repo.get_payment_by_reference(event.reference)
        if not payment:
            logger.warning("webhook_unknown_reference ref=%s", event.reference)
            return
        await self._apply_event(event, payment=payment)

    # ---------- Cancel ----------

    async def cancel_active(self, user_id: uuid.UUID) -> SubscriptionOut:
        sub = await self.repo.get_active_for_user(user_id)
        if not sub:
            raise NotFoundError("No active subscription to cancel.")
        sub.status = SUB_STATUS_CANCELLED
        sub.cancelled_at = datetime.now(UTC)
        await self.repo.commit()
        await self.repo.refresh(sub)
        return SubscriptionOut.model_validate(sub)

    # ---------- Internals ----------

    async def _apply_event(
        self, event: WebhookEvent, *, payment: Payment
    ) -> ConfirmResponse:
        sub: Subscription | None = None

        if event.status == "succeeded":
            payment.status = PAY_STATUS_SUCCEEDED
            payment.paid_at = datetime.now(UTC)
            payment.provider_reference = (
                event.provider_reference or payment.provider_reference
            )
            payment.provider_payload = event.raw or {}
            if event.amount_minor:
                payment.amount_float = event.amount_minor / 100.0

            if payment.subscription_id:
                sub_row = await self.repo.get_subscription(payment.subscription_id)
                if sub_row:
                    cycle = CYCLE_MONTHLY
                    plan = None
                    if sub_row.plan_id:
                        plan = await self.repo.get_plan(sub_row.plan_id)
                        if plan:
                            cycle = plan.billing_cycle
                    days = _CYCLE_DAYS.get(cycle, 30)
                    now = datetime.now(UTC)
                    sub_row.status = SUB_STATUS_ACTIVE
                    sub_row.current_period_start = now
                    sub_row.current_period_end = now + timedelta(days=days)
                    sub_row.provider_reference = (
                        event.provider_reference or sub_row.provider_reference
                    )
                    sub = sub_row

            await self.repo.commit()
            message = "Payment confirmed. Subscription activated."
            status = "succeeded"

        elif event.status == "failed":
            payment.status = PAY_STATUS_FAILED
            payment.failure_reason = (
                "Payment was declined by the provider."
            )
            payment.provider_payload = event.raw or {}
            if payment.subscription_id:
                sub_row = await self.repo.get_subscription(payment.subscription_id)
                if sub_row:
                    sub_row.status = SUB_STATUS_EXPIRED
            await self.repo.commit()
            message = "Payment failed. Please try again."
            status = "failed"

        elif event.status == "refunded":
            payment.status = "refunded"
            payment.provider_payload = event.raw or {}
            if payment.subscription_id:
                sub_row = await self.repo.get_subscription(payment.subscription_id)
                if sub_row:
                    sub_row.status = SUB_STATUS_EXPIRED
            await self.repo.commit()
            message = "Payment was refunded."
            status = "refunded"

        else:
            # pending — nothing changes yet
            await self.repo.commit()
            message = "Payment is still pending."
            status = "pending"

        await self.repo.refresh(payment)
        return ConfirmResponse(
            payment=PaymentOut.model_validate(payment),
            subscription=self._to_detail(sub) if sub else None,
            status=status,
            message=message,
        )

    def _to_detail(self, sub: Subscription | None) -> SubscriptionDetail:
        if sub is None:
            raise NotFoundError("Subscription not found.")
        base = SubscriptionOut.model_validate(sub).model_dump()
        plan = getattr(sub, "plan", None)
        return SubscriptionDetail(
            **base,
            plan=PlanOut.model_validate(plan) if plan else None,
        )
