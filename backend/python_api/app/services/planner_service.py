"""Planner service — creates plans and generates study sessions."""
from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, time, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.models.plan import StudyPlan, StudySession
from app.repositories.plan_repo import PlanRepository
from app.services.notification.hooks import on_session_completed
from app.schemas.planner import (
    ExamPlanCreate,
    SessionCompleteRequest,
    StudyPlanDetail,
    StudyPlanOut,
    StudySessionOut,
    SubjectPlanCreate,
)

# How many study slots per day — 45-minute blocks.
SESSION_BLOCK_MINUTES = 45
# Preferred hours for generated sessions.
SLOT_START_HOURS = (17, 18, 19, 20, 21)


class PlannerService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.repo = PlanRepository(session)

    # ---------- Exam plan ----------

    async def create_exam_plan(
        self, user_id: uuid.UUID, payload: ExamPlanCreate
    ) -> StudyPlanDetail:
        start = payload.start_date or date.today()
        if payload.target_date <= start:
            raise ValidationError("Target date must be after the start date.")

        total_days = (payload.target_date - start).days
        if total_days < 1:
            raise ValidationError("Not enough days between start and target.")

        sessions_per_day = max(1, payload.daily_minutes // SESSION_BLOCK_MINUTES)

        plan = StudyPlan(
            user_id=user_id,
            plan_type="exam",
            title=f"{payload.exam_name} Prep",
            exam_system=payload.exam_system,
            exam_level=payload.exam_level,
            exam_name=payload.exam_name,
            start_date=start,
            target_date=payload.target_date,
            daily_minutes=payload.daily_minutes,
            metadata_json={
                "subjects": payload.subjects,
                "sessions_per_day": sessions_per_day,
            },
            is_active=True,
        )
        await self.repo.create_plan(plan)

        sessions = self._generate_sessions(
            user_id=user_id,
            plan=plan,
            subjects=payload.subjects,
            start_date=start,
            total_days=total_days,
            sessions_per_day=sessions_per_day,
        )
        await self.repo.add_sessions(sessions)
        await self.session.commit()

        refreshed = await self.repo.get_plan(user_id, plan.id)
        return self._to_detail(refreshed)

    # ---------- Subject plan ----------

    async def create_subject_plan(
        self, user_id: uuid.UUID, payload: SubjectPlanCreate
    ) -> StudyPlanDetail:
        start = payload.start_date or date.today()
        target = payload.target_date or (start + timedelta(days=payload.duration_days))
        if target <= start:
            raise ValidationError("Target date must be after the start date.")

        total_days = (target - start).days
        sessions_per_day = max(1, payload.daily_minutes // SESSION_BLOCK_MINUTES)

        title = (
            f"{payload.subject} — {payload.topic}"
            if payload.topic
            else f"{payload.subject} Plan"
        )

        plan = StudyPlan(
            user_id=user_id,
            plan_type="subject",
            title=title,
            subject=payload.subject,
            start_date=start,
            target_date=target,
            daily_minutes=payload.daily_minutes,
            metadata_json={
                "topic": payload.topic,
                "sessions_per_day": sessions_per_day,
            },
            is_active=True,
        )
        await self.repo.create_plan(plan)

        sessions = self._generate_sessions(
            user_id=user_id,
            plan=plan,
            subjects=[payload.subject],
            start_date=start,
            total_days=total_days,
            sessions_per_day=sessions_per_day,
            fixed_topic=payload.topic,
        )
        await self.repo.add_sessions(sessions)
        await self.session.commit()

        refreshed = await self.repo.get_plan(user_id, plan.id)
        return self._to_detail(refreshed)

    # ---------- Read ----------

    async def list_plans(self, user_id: uuid.UUID) -> list[StudyPlanOut]:
        plans = await self.repo.list_plans(user_id)
        return [StudyPlanOut.model_validate(p) for p in plans]

    async def get_plan(self, user_id: uuid.UUID, plan_id: uuid.UUID) -> StudyPlanDetail:
        plan = await self.repo.get_plan(user_id, plan_id)
        if not plan:
            raise NotFoundError("Plan not found.")
        return self._to_detail(plan)

    async def upcoming_sessions(self, user_id: uuid.UUID) -> list[StudySessionOut]:
        rows = await self.repo.upcoming_sessions(user_id)
        return [StudySessionOut.model_validate(s) for s in rows]

    # ---------- Session lifecycle ----------

    async def start_session(
        self, user_id: uuid.UUID, session_id: uuid.UUID
    ) -> StudySessionOut:
        s = await self.repo.get_session(user_id, session_id)
        if not s:
            raise NotFoundError("Session not found.")
        await self.repo.set_session_started(s)
        await self.session.commit()
        return StudySessionOut.model_validate(s)

    async def complete_session(
        self,
        user_id: uuid.UUID,
        session_id: uuid.UUID,
        payload: SessionCompleteRequest,
    ) -> StudySessionOut:
        s = await self.repo.get_session(user_id, session_id)
        if not s:
            raise NotFoundError("Session not found.")
        await self.repo.set_session_completed(s, payload.confidence_after, payload.notes)

        # Realtime notification hook (non-blocking, swallows errors)
        try:
            from app.models.user import User

            user = await self.session.get(User, user_id)
            if user is not None:
                await on_session_completed(self.session, user=user, session=s)
        except Exception:
            pass  # non-blocking
        await self.session.commit()
        return StudySessionOut.model_validate(s)

    # ---------- Internal ----------

    def _generate_sessions(
        self,
        *,
        user_id: uuid.UUID,
        plan: StudyPlan,
        subjects: list[str],
        start_date: date,
        total_days: int,
        sessions_per_day: int,
        fixed_topic: str | None = None,
    ) -> list[StudySession]:
        sessions: list[StudySession] = []
        subject_cycle = subjects or ["General"]
        cycle_index = 0

        # Reserve the last 2 days before target for revision (if enough days).
        study_days = max(1, total_days - 2)

        for day_offset in range(study_days):
            day = start_date + timedelta(days=day_offset)
            for slot_index in range(sessions_per_day):
                subject = subject_cycle[cycle_index % len(subject_cycle)]
                cycle_index += 1

                hour = SLOT_START_HOURS[slot_index % len(SLOT_START_HOURS)]
                scheduled = datetime.combine(day, time(hour=hour)).replace(tzinfo=UTC)

                topic = fixed_topic
                title = (
                    f"{subject} — {topic}" if topic else f"{subject} study session"
                )

                sessions.append(
                    StudySession(
                        user_id=user_id,
                        plan_id=plan.id,
                        title=title,
                        subject=subject,
                        topic=topic,
                        objective=None,
                        scheduled_for=scheduled,
                        duration_minutes=SESSION_BLOCK_MINUTES,
                        status="scheduled",
                        metadata_json={},
                    )
                )
        return sessions

    def _to_detail(self, plan: StudyPlan | None) -> StudyPlanDetail:
        if plan is None:
            raise NotFoundError("Plan not found.")
        return StudyPlanDetail(
            **StudyPlanOut.model_validate(plan).model_dump(),
            sessions=[StudySessionOut.model_validate(s) for s in (plan.sessions or [])],
        )
