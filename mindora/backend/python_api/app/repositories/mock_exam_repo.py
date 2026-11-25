"""Mock exam repository."""
from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.mock_exam import MockExam


class MockExamRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(self, exam: MockExam) -> MockExam:
        self.session.add(exam)
        await self.session.flush()
        return exam

    async def get(
        self, exam_id: uuid.UUID, user_id: uuid.UUID | None = None
    ) -> MockExam | None:
        stmt = (
            select(MockExam)
            .where(
                MockExam.id == exam_id,
                MockExam.deleted_at.is_(None),
            )
            .options(
                selectinload(MockExam.questions),
            )
        )
        if user_id is not None:
            stmt = stmt.where(MockExam.user_id == user_id)
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def list_for_user(self, user_id: uuid.UUID) -> list[MockExam]:
        stmt = (
            select(MockExam)
            .where(
                MockExam.user_id == user_id,
                MockExam.deleted_at.is_(None),
            )
            .order_by(MockExam.created_at.desc())
        )
        return list((await self.session.execute(stmt)).scalars().all())

    async def commit(self) -> None:
        await self.session.commit()

    async def refresh(self, exam: MockExam) -> MockExam:
        await self.session.refresh(exam)
        return exam
