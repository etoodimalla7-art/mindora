"""Subscription, payment, and plan models."""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDMixin

# Subscription statuses
SUB_STATUS_PENDING = "pending"          # waiting for payment confirmation
SUB_STATUS_ACTIVE = "active"
SUB_STATUS_PAST_DUE = "past_due"
SUB_STATUS_CANCELLED = "cancelled"
SUB_STATUS_EXPIRED = "expired"

# Payment statuses
PAY_STATUS_PENDING = "pending"
PAY_STATUS_SUCCEEDED = "succeeded"
PAY_STATUS_FAILED = "failed"
PAY_STATUS_REFUNDED = "refunded"

# Billing cycles
CYCLE_MONTHLY = "monthly"
CYCLE_QUARTERLY = "quarterly"
CYCLE_YEARLY = "yearly"

# Plan tiers
TIER_FREE = "free"
TIER_STUDENT = "student"           # main paid tier
TIER_PREMIUM = "premium"           # heavier usage


class Plan(Base, UUIDMixin, TimestampMixin):
    """A purchasable subscription plan.

    Plans are configured server-side and can be edited by admins.
    No hardcoded prices — everything is in this table.
    """

    __tablename__ = "plans"

    code: Mapped[str] = mapped_column(
        String(40), unique=True, index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    tier: Mapped[str] = mapped_column(String(20), nullable=False, default=TIER_STUDENT)

    # Amount stored in minor units (e.g. XAF has no decimals; USD cents).
    # Currency code is ISO 4217 (XAF, USD, EUR, ...).
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="XAF")
    billing_cycle: Mapped[str] = mapped_column(
        String(20), nullable=False, default=CYCLE_MONTHLY
    )

    # Feature flags granted when active (parsed by the app).
    features: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    # Visibility
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class Subscription(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    """An active or historical subscription for a user."""

    __tablename__ = "subscriptions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    plan_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("plans.id"), index=True, nullable=False
    )

    status: Mapped[str] = mapped_column(
        String(20), default=SUB_STATUS_PENDING, nullable=False, index=True
    )

    current_period_start: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    current_period_end: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Provider-specific reference (e.g. Flutterwave subscription id).
    provider: Mapped[str] = mapped_column(String(40), nullable=False)
    provider_reference: Mapped[str | None] = mapped_column(
        String(120), nullable=True, index=True
    )

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    plan = relationship("Plan", lazy="selectin")


class Payment(Base, UUIDMixin, TimestampMixin):
    """Individual payment attempts tied to a subscription."""

    __tablename__ = "payments"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    subscription_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("subscriptions.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    plan_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("plans.id", ondelete="SET NULL"), nullable=True
    )

    status: Mapped[str] = mapped_column(
        String(20), default=PAY_STATUS_PENDING, nullable=False, index=True
    )

    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="XAF")

    # Our own unique reference (sent to the provider).
    reference: Mapped[str] = mapped_column(
        String(80), unique=True, index=True, nullable=False
    )
    # The provider's transaction id, when known.
    provider_reference: Mapped[str | None] = mapped_column(
        String(120), nullable=True, index=True
    )
    provider: Mapped[str] = mapped_column(String(40), nullable=False)

    # Where the user is redirected after checkout.
    redirect_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    failure_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    paid_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Full payload from the provider (for audit / reconciliation).
    provider_payload: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    # Raw amount for convenience.
    amount_float: Mapped[float | None] = mapped_column(Float, nullable=True)
