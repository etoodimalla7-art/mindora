"""Credit ledger service — balance, grants, spends."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ForbiddenError, ValidationError
from app.models.credit import (
    CREDIT_REASON_CONTRIBUTION,
    CREDIT_REASON_DOWNLOAD,
    CREDIT_REASON_SIGNUP,
    CreditLedger,
    Download,
)
from app.models.document import DOC_STATUS_APPROVED, Document

SIGNUP_BONUS = 3
CONTRIBUTION_REWARD = 5
DOWNLOAD_COST = 1


class CreditService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def balance(self, user_id: uuid.UUID) -> int:
        stmt = select(func.coalesce(func.sum(CreditLedger.delta), 0)).where(
            CreditLedger.user_id == user_id
        )
        return int((await self.session.execute(stmt)).scalar() or 0)

    async def grant(
        self,
        user_id: uuid.UUID,
        delta: int,
        reason: str,
        reference_id: uuid.UUID | None = None,
        reference_type: str | None = None,
        notes: str | None = None,
    ) -> CreditLedger:
        entry = CreditLedger(
            user_id=user_id,
            delta=delta,
            reason=reason,
            reference_id=reference_id,
            reference_type=reference_type,
            notes=notes,
        )
        self.session.add(entry)
        await self.session.flush()
        return entry

    async def grant_signup_bonus(self, user_id: uuid.UUID) -> CreditLedger:
        return await self.grant(
            user_id,
            SIGNUP_BONUS,
            CREDIT_REASON_SIGNUP,
            notes=f"Welcome bonus: {SIGNUP_BONUS} free downloads.",
        )

    async def history(
        self, user_id: uuid.UUID, limit: int = 50
    ) -> list[CreditLedger]:
        stmt = (
            select(CreditLedger)
            .where(CreditLedger.user_id == user_id)
            .order_by(CreditLedger.created_at.desc())
            .limit(limit)
        )
        return list((await self.session.execute(stmt)).scalars().all())

    async def spend_download(
        self,
        *,
        user_id: uuid.UUID,
        document: Document,
        ip_address: str | None,
        user_agent: str | None,
    ) -> Download:
        """Charge 1 credit for downloading someone else's approved document.

        Owners download their own documents for free.
        """
        if document.status != DOC_STATUS_APPROVED and document.owner_id != user_id:
            raise ForbiddenError("This document is not available for download.")

        is_owner = document.owner_id == user_id
        cost = 0 if is_owner else DOWNLOAD_COST

        if cost > 0:
            current = await self.balance(user_id)
            if current < cost:
                raise ValidationError(
                    "You do not have enough credits. Contribute 5 documents "
                    "or subscribe for unlimited access."
                )
            await self.grant(
                user_id,
                -cost,
                CREDIT_REASON_DOWNLOAD,
                reference_id=document.id,
                reference_type="document",
                notes=f"Download of '{document.title}'.",
            )

        download = Download(
            user_id=user_id,
            document_id=document.id,
            credits_spent=cost,
            downloaded_at=datetime.now(UTC),
            ip_address=ip_address,
            user_agent=user_agent,
            size_bytes=document.size_bytes or 0,
        )
        self.session.add(download)

        document.download_count = (document.download_count or 0) + 1

        await self.session.flush()
        return download

    async def reward_contribution(
        self, *, user_id: uuid.UUID, document_id: uuid.UUID, title: str
    ) -> CreditLedger:
        return await self.grant(
            user_id,
            CONTRIBUTION_REWARD,
            CREDIT_REASON_CONTRIBUTION,
            reference_id=document_id,
            reference_type="document",
            notes=f"Contribution approved: '{title}'.",
        )
