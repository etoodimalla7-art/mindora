"""Subscription & payment repository."""
from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.subscription import Payment, Plan, Subscription


class SubscriptionRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Plans ----------

    async def list_active_plans(self) -> list[Plan]:
        stmt = (
            select(Plan)
            .where(Plan.is_active.is_(True))
            .order_by(Plan.sort_order.asc(), Plan.amount_minor.asc())
        )
        return list((await self.session.execute(stmt)).scalars().all())

    async def get_plan_by_code(self, code: str) -> Plan | None:
        stmt = select(Plan).where(Plan.code == code)
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def get_plan(self, plan_id: uuid.UUID) -> Plan | None:
        stmt = select(Plan).where(Plan.id == plan_id)
        return (await self.session.execute(stmt)).scalar_one_or_none()

    # ---------- Subscriptions ----------

    async def get_active_for_user(
        self, user_id: uuid.UUID
    ) -> Subscription | None:
        stmt = (
            select(Subscription)
            .where(
                Subscription.user_id == user_id,
                Subscription.status == "active",
                Subscription.deleted_at.is_(None),
            )
            .order_by(Subscription.created_at.desc())
            .limit(1)
            .options(selectinload(Subscription.plan))
        )
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def get_subscription(
        self, subscription_id: uuid.UUID, user_id: uuid.UUID | None = None
    ) -> Subscription | None:
        stmt = (
            select(Subscription)
            .where(
                Subscription.id == subscription_id,
                Subscription.deleted_at.is_(None),
            )
            .options(selectinload(Subscription.plan))
        )
        if user_id is not None:
            stmt = stmt.where(Subscription.user_id == user_id)
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def list_for_user(self, user_id: uuid.UUID) -> list[Subscription]:
        stmt = (
            select(Subscription)
            .where(
                Subscription.user_id == user_id,
                Subscription.deleted_at.is_(None),
            )
            .order_by(Subscription.created_at.desc())
            .options(selectinload(Subscription.plan))
        )
        return list((await self.session.execute(stmt)).scalars().all())

    async def create_subscription(self, sub: Subscription) -> Subscription:
        self.session.add(sub)
        await self.session.flush()
        return sub

    # ---------- Payments ----------

    async def create_payment(self, payment: Payment) -> Payment:
        self.session.add(payment)
        await self.session.flush()
        return payment

    async def get_payment_by_reference(self, reference: str) -> Payment | None:
        stmt = select(Payment).where(Payment.reference == reference)
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def list_payments_for_user(
        self, user_id: uuid.UUID, limit: int = 50
    ) -> list[Payment]:
        stmt = (
            select(Payment)
            .where(Payment.user_id == user_id)
            .order_by(Payment.created_at.desc())
            .limit(limit)
        )
        return list((await self.session.execute(stmt)).scalars().all())

    # ---------- Utility ----------

    async def commit(self) -> None:
        await self.session.commit()

    async def refresh(self, obj):
        await self.session.refresh(obj)
        return obj
