"""Admin moderation service."""
from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, NotFoundError
from app.models.document import (
    DOC_STATUS_APPROVED,
    DOC_STATUS_REJECTED,
    DOC_STATUS_UNDER_REVIEW,
    Document,
)
from app.schemas.admin import (
    AdminDocumentRow,
    ApproveResponse,
    RejectResponse,
)
from app.services.credit_service import CONTRIBUTION_REWARD, CreditService


class AdminService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.credits = CreditService(session)

    async def list_documents(
        self, status_filter: str | None = None, limit: int = 100
    ) -> list[AdminDocumentRow]:
        stmt = select(Document).where(Document.deleted_at.is_(None))
        if status_filter:
            stmt = stmt.where(Document.status == status_filter)
        stmt = stmt.order_by(Document.created_at.desc()).limit(limit)
        rows = (await self.session.execute(stmt)).scalars().all()
        return [AdminDocumentRow.model_validate(r) for r in rows]

    async def approve(self, doc_id: uuid.UUID) -> ApproveResponse:
        doc = await self._get(doc_id)
        if doc.status == DOC_STATUS_APPROVED:
            raise ConflictError("This document is already approved.")
        if doc.status != DOC_STATUS_UNDER_REVIEW:
            raise ConflictError(
                f"Cannot approve a document in status '{doc.status}'."
            )
        doc.status = DOC_STATUS_APPROVED
        doc.rejection_reason = None

        await self.credits.reward_contribution(
            user_id=doc.owner_id,
            document_id=doc.id,
            title=doc.title,
        )

        await self.session.commit()
        return ApproveResponse(
            document_id=doc.id,
            status=doc.status,
            contributor_reward=CONTRIBUTION_REWARD,
            message="Document approved and contributor rewarded.",
        )

    async def reject(self, doc_id: uuid.UUID, reason: str) -> RejectResponse:
        doc = await self._get(doc_id)
        if doc.status == DOC_STATUS_REJECTED:
            raise ConflictError("This document is already rejected.")
        doc.status = DOC_STATUS_REJECTED
        doc.rejection_reason = reason
        await self.session.commit()
        return RejectResponse(
            document_id=doc.id,
            status=doc.status,
            reason=reason,
            message="Document rejected. The contributor will see the reason.",
        )

    async def _get(self, doc_id: uuid.UUID) -> Document:
        stmt = select(Document).where(
            Document.id == doc_id, Document.deleted_at.is_(None)
        )
        doc = (await self.session.execute(stmt)).scalar_one_or_none()
        if not doc:
            raise NotFoundError("Document not found.")
        return doc
