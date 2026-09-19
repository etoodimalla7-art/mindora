from datetime import date, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.planner.models import StudyPlan
from api.modules.study_sessions.models import StudySession


class PlannerRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_plan(
        self, user_id: str, mode: str, target_exam_name: str | None,
        subjects: list[str], start_date: date, end_date: date,
    ) -> StudyPlan:
        plan = StudyPlan(
            user_id=to_uuid(user_id), mode=mode, target_exam_name=target_exam_name,
            subjects=subjects, start_date=start_date, end_date=end_date, status="active",
        )
        self.db.add(plan)
        await self.db.commit()
        await self.db.refresh(plan)
        return plan

    async def bulk_create_sessions(
        self, plan_id: str, user_id: str, sessions_data: list[dict]
    ) -> list[StudySession]:
        sessions = [
            StudySession(
                user_id=to_uuid(user_id),
                plan_id=to_uuid(plan_id),
                subject_id=to_uuid(d["subject_id"]) if d.get("subject_id") else None,
                topic_id=to_uuid(d["topic_id"]) if d.get("topic_id") else None,
                subject_name=d["subject_name"],
                topic_title=d["topic_title"],
                scheduled_at=d["scheduled_at"],
                duration_minutes=d["duration_minutes"],
                status="pending",
            )
            for d in sessions_data
        ]
        self.db.add_all(sessions)
        await self.db.commit()
        for session in sessions:
            await self.db.refresh(session)
        return sessions

    async def get_owned(self, plan_id: str, user_id: str) -> StudyPlan | None:
        result = await self.db.execute(
            select(StudyPlan)
            .where(StudyPlan.id == to_uuid(plan_id))
            .where(StudyPlan.user_id == to_uuid(user_id))
        )
        return result.scalar_one_or_none()

    async def list_sessions_for_plan(self, plan_id: str) -> list[StudySession]:
        result = await self.db.execute(
            select(StudySession)
            .where(StudySession.plan_id == to_uuid(plan_id))
            .order_by(StudySession.scheduled_at)
        )
        return list(result.scalars().all())

    async def apply_reschedule(self, updates: list[tuple[StudySession, datetime]]) -> None:
        for session, new_time in updates:
            session.scheduled_at = new_time
            session.status = "pending"
        await self.db.commit()

    async def get_latest_active_exam_plan(self, user_id: str) -> StudyPlan | None:
        """Feeds notification generation (Phase 14) and could feed the
        readiness screen's default exam name in a later frontend pass."""
        result = await self.db.execute(
            select(StudyPlan)
            .where(StudyPlan.user_id == to_uuid(user_id))
            .where(StudyPlan.mode == "exam")
            .where(StudyPlan.status == "active")
            .order_by(StudyPlan.created_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()
