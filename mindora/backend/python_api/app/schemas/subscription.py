"""Subscription, plan, and payment schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class PlanOut(BaseModel):
    id: uuid.UUID
    code: str
    name: str
    description: str | None = None
    tier: str
    amount_minor: int
    currency: str
    billing_cycle: str
    features: dict = Field(default_factory=dict)
    is_active: bool
    sort_order: int

    class Config:
        from_attributes = True


class SubscriptionOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    plan_id: uuid.UUID
    status: str
    current_period_start: datetime | None = None
    current_period_end: datetime | None = None
    cancelled_at: datetime | None = None
    provider: str
    provider_reference: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class SubscriptionDetail(SubscriptionOut):
    plan: PlanOut | None = None


class PaymentOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    subscription_id: uuid.UUID | None = None
    plan_id: uuid.UUID | None = None
    status: str
    amount_minor: int
    currency: str
    reference: str
    provider_reference: str | None = None
    provider: str
    redirect_url: str | None = None
    failure_reason: str | None = None
    paid_at: datetime | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class CheckoutRequestSchema(BaseModel):
    plan_code: str = Field(min_length=1, max_length=40)


class CheckoutResponseSchema(BaseModel):
    payment: PaymentOut
    checkout_url: str
    provider: str


class ConfirmRequest(BaseModel):
    """Called by the frontend after the user returns from the provider."""

    reference: str = Field(min_length=1, max_length=80)


class ConfirmResponse(BaseModel):
    payment: PaymentOut
    subscription: SubscriptionDetail | None = None
    status: str
    message: str


class CancelResponse(BaseModel):
    subscription_id: uuid.UUID
    status: str
    message: str
