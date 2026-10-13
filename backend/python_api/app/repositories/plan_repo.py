"""Study plan and session repository."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.plan import StudyPlan, StudySession


class PlanRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_plans(self, user_id: uuid.UUID) -> list[StudyPlan]:
        stmt = (
            select(StudyPlan)
            .where(StudyPlan.user_id == user_id, StudyPlan.deleted_at.is_(None))
            .order_by(StudyPlan.created_at.desc())
        )
        return list((await self.session.execute(stmt)).scalars().all())

    async def get_plan(self, user_id: uuid.UUID, plan_id: uuid.UUID) -> StudyPlan | None:
        stmt = (
            select(StudyPlan)
            .where(
                StudyPlan.id == plan_id,
                StudyPlan.user_id == user_id,
                StudyPlan.deleted_at.is_(None),
            )
            .options(selectinload(StudyPlan.sessions))
        )
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def create_plan(self, plan: StudyPlan) -> StudyPlan:
        self.session.add(plan)
        await self.session.flush()
        return plan

    async def add_sessions(self, sessions: list[StudySession]) -> None:
        self.session.add_all(sessions)
        await self.session.flush()

    async def upcoming_sessions(
        self, user_id: uuid.UUID, limit: int = 30
    ) -> list[StudySession]:
        stmt = (
            select(StudySession)
            .where(StudySession.user_id == user_id)
            .order_by(StudySession.scheduled_for.asc())
            .limit(limit)
        )
        return list((await self.session.execute(stmt)).scalars().all())

    async def get_session(
        self, user_id: uuid.UUID, session_id: uuid.UUID
    ) -> StudySession | None:
        stmt = select(StudySession).where(
            StudySession.id == session_id, StudySession.user_id == user_id
        )
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def set_session_started(self, s: StudySession) -> None:
        s.status = "in_progress"
        s.started_at = datetime.now(UTC)
        await self.session.flush()

    async def set_session_completed(
        self,
        s: StudySession,
        confidence_after: float | None,
        notes: str | None,
    ) -> None:
        s.status = "completed"
        s.completed_at = datetime.now(UTC)
        meta = dict(s.metadata_json or {})
        if confidence_after is not None:
            meta["confidence_after"] = confidence_after
        if notes:
            meta["notes"] = notes
        s.metadata_json = meta
        await self.session.flush()

    async def deactivate_other_plans(self, user_id: uuid.UUID, keep_id: uuid.UUID) -> None:
        stmt = select(StudyPlan).where(
            StudyPlan.user_id == user_id,
            StudyPlan.id != keep_id,
            StudyPlan.is_active.is_(True),
        )
        for p in (await self.session.execute(stmt)).scalars().all():
            p.is_active = False
        await self.session.flush()
