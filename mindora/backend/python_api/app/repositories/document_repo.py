"""Document repository."""
from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.document import Document


class DocumentRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(self, doc: Document) -> Document:
        self.session.add(doc)
        await self.session.flush()
        return doc

    async def get(
        self, doc_id: uuid.UUID, owner_id: uuid.UUID | None = None
    ) -> Document | None:
        stmt = (
            select(Document)
            .where(Document.id == doc_id, Document.deleted_at.is_(None))
            .options(
                selectinload(Document.analysis),
                selectinload(Document.duplicates),
            )
        )
        if owner_id is not None:
            stmt = stmt.where(Document.owner_id == owner_id)
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def list_for_owner(self, owner_id: uuid.UUID) -> list[Document]:
        stmt = (
            select(Document)
            .where(
                Document.owner_id == owner_id,
                Document.deleted_at.is_(None),
            )
            .order_by(Document.created_at.desc())
        )
        return list((await self.session.execute(stmt)).scalars().all())

    async def commit(self) -> None:
        await self.session.commit()

    async def refresh(self, doc: Document) -> Document:
        await self.session.refresh(doc)
        return doc
