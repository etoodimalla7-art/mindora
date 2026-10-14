"""Subscription REST endpoints."""
from __future__ import annotations

from fastapi import APIRouter, status

from app.api.deps import CurrentUser, CurrentUserId, SessionDep
from app.schemas.subscription import (
    CancelResponse,
    CheckoutRequestSchema,
    CheckoutResponseSchema,
    ConfirmRequest,
    ConfirmResponse,
    PaymentOut,
    PlanOut,
    SubscriptionDetail,
    SubscriptionOut,
)
from app.services.subscription_service import SubscriptionService

router = APIRouter()


@router.get("/plans", response_model=list[PlanOut])
async def list_plans(
    session: SessionDep, _user: CurrentUser
) -> list[PlanOut]:
    return await SubscriptionService(session).list_plans()


@router.get("/me", response_model=SubscriptionDetail | None)
async def get_my_subscription(
    session: SessionDep, user_id: CurrentUserId
) -> SubscriptionDetail | None:
    return await SubscriptionService(session).get_active(user_id)


@router.get("/history", response_model=list[SubscriptionOut])
async def list_my_subscriptions(
    session: SessionDep, user_id: CurrentUserId
) -> list[SubscriptionOut]:
    return await SubscriptionService(session).list_subscriptions(user_id)


@router.get("/payments", response_model=list[PaymentOut])
async def list_my_payments(
    session: SessionDep, user_id: CurrentUserId
) -> list[PaymentOut]:
    return await SubscriptionService(session).list_payments(user_id)


@router.post(
    "/checkout",
    response_model=CheckoutResponseSchema,
    status_code=status.HTTP_201_CREATED,
)
async def start_checkout(
    payload: CheckoutRequestSchema,
    session: SessionDep,
    user: CurrentUser,
) -> CheckoutResponseSchema:
    """Create a payment and return the provider's checkout URL."""
    return await SubscriptionService(session).start_checkout(
        user_id=user.id,  # type: ignore[attr-defined]
        plan_code=payload.plan_code,
        user_email=user.email,  # type: ignore[attr-defined]
        user_name=getattr(user, "full_name", None) or user.email,  # type: ignore[attr-defined]
    )


@router.post("/confirm", response_model=ConfirmResponse)
async def confirm_payment(
    payload: ConfirmRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> ConfirmResponse:
    """Called by the frontend after returning from the payment provider."""
    return await SubscriptionService(session).confirm_payment(
        user_id, payload.reference
    )


@router.post("/cancel", response_model=CancelResponse)
async def cancel_subscription(
    session: SessionDep, user_id: CurrentUserId
) -> CancelResponse:
    sub = await SubscriptionService(session).cancel_active(user_id)
    return CancelResponse(
        subscription_id=sub.id,
        status=sub.status,
        message="Subscription cancelled. Access remains until the end of the period.",
    )
