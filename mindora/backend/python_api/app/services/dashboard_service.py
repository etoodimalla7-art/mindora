"""Computes the home dashboard payload for a user."""
from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.plan import StudyPlan, StudySession
from app.models.progress import TopicProgress
from app.schemas.dashboard import (
    DashboardResponse,
    ExamCountdown,
    ReadinessBreakdown,
    RecentActivity,
    TodayFocus,
    WeakTopic,
)


class DashboardService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def build(self, user_id: uuid.UUID) -> DashboardResponse:
        streak = await self._compute_streak(user_id)
        countdown = await self._next_exam(user_id)
        focus = await self._today_focus(user_id)
        recent = await self._recent_activity(user_id)
        weak = await self._weak_topics(user_id)
        readiness, breakdown = await self._readiness(user_id, weak, streak)

        return DashboardResponse(
            streak_days=streak,
            exam_countdown=countdown,
            today_focus=focus,
            readiness_score=readiness,
            readiness_breakdown=breakdown,
            weak_topics=weak,
            recent_activity=recent,
        )

    async def _compute_streak(self, user_id: uuid.UUID) -> int:
        stmt = (
            select(func.date(StudySession.completed_at))
            .where(
                StudySession.user_id == user_id,
                StudySession.status == "completed",
                StudySession.completed_at.is_not(None),
            )
            .distinct()
            .order_by(func.date(StudySession.completed_at).desc())
        )
        rows = (await self.session.execute(stmt)).scalars().all()
        if not rows:
            return 0

        days = set(rows)
        today = date.today()
        if today not in days and (today - timedelta(days=1)) not in days:
            return 0

        expected = today if today in days else today - timedelta(days=1)
        streak = 0
        while expected in days:
            streak += 1
            expected -= timedelta(days=1)
        return streak

    async def _next_exam(self, user_id: uuid.UUID) -> ExamCountdown | None:
        stmt = (
            select(StudyPlan)
            .where(
                StudyPlan.user_id == user_id,
                StudyPlan.is_active.is_(True),
                StudyPlan.target_date.is_not(None),
                StudyPlan.deleted_at.is_(None),
                StudyPlan.target_date >= date.today(),
            )
            .order_by(StudyPlan.target_date.asc())
            .limit(1)
        )
        plan = (await self.session.execute(stmt)).scalar_one_or_none()
        if not plan or not plan.target_date:
            return None
        days = (plan.target_date - date.today()).days
        return ExamCountdown(
            exam_name=plan.exam_name or plan.title,
            target_date=plan.target_date,
            days_remaining=max(days, 0),
        )

    async def _today_focus(self, user_id: uuid.UUID) -> TodayFocus | None:
        now = datetime.now(UTC)
        end = now + timedelta(hours=24)
        stmt = (
            select(StudySession)
            .where(
                StudySession.user_id == user_id,
                StudySession.status.in_(["scheduled", "in_progress"]),
                StudySession.scheduled_for >= now - timedelta(hours=6),
                StudySession.scheduled_for <= end,
            )
            .order_by(StudySession.scheduled_for.asc())
            .limit(1)
        )
        s = (await self.session.execute(stmt)).scalar_one_or_none()
        if not s:
            return None
        return TodayFocus(
            session_id=s.id,
            title=s.title,
            subject=s.subject,
            topic=s.topic,
            objective=s.objective,
            duration_minutes=s.duration_minutes,
            scheduled_for=s.scheduled_for,
        )

    async def _recent_activity(self, user_id: uuid.UUID) -> list[RecentActivity]:
        stmt = (
            select(StudySession)
            .where(
                StudySession.user_id == user_id,
                StudySession.status == "completed",
            )
            .order_by(StudySession.completed_at.desc())
            .limit(3)
        )
        rows = (await self.session.execute(stmt)).scalars().all()
        return [
            RecentActivity(
                session_id=s.id,
                title=s.title,
                subject=s.subject,
                completed_at=s.completed_at,
                duration_minutes=s.duration_minutes,
            )
            for s in rows
        ]

    async def _weak_topics(self, user_id: uuid.UUID, limit: int = 3) -> list[WeakTopic]:
        stmt = (
            select(TopicProgress)
            .where(
                TopicProgress.user_id == user_id,
                TopicProgress.questions_seen >= 3,
            )
            .order_by(TopicProgress.mastery.asc())
            .limit(limit)
        )
        rows = (await self.session.execute(stmt)).scalars().all()
        return [
            WeakTopic(subject=r.subject, topic=r.topic, mastery=r.mastery)
            for r in rows
        ]

    async def _readiness(
        self,
        user_id: uuid.UUID,
        weak: list[WeakTopic],
        streak: int,
    ) -> tuple[int, ReadinessBreakdown]:
        knowledge_stmt = select(func.avg(TopicProgress.mastery)).where(
            TopicProgress.user_id == user_id
        )
        knowledge = (await self.session.execute(knowledge_stmt)).scalar() or 0.0

        practice_stmt = select(
            func.coalesce(func.sum(TopicProgress.questions_correct), 0),
            func.coalesce(func.sum(TopicProgress.questions_seen), 0),
        ).where(TopicProgress.user_id == user_id)
        correct, seen = (await self.session.execute(practice_stmt)).one()
        practice = (correct / seen) if seen else 0.0

        cutoff = datetime.now(UTC) - timedelta(days=14)
        total_stmt = select(func.count(StudySession.id)).where(
            StudySession.user_id == user_id,
            StudySession.scheduled_for >= cutoff,
        )
        done_stmt = select(func.count(StudySession.id)).where(
            StudySession.user_id == user_id,
            StudySession.scheduled_for >= cutoff,
            StudySession.status == "completed",
        )
        total = (await self.session.execute(total_stmt)).scalar() or 0
        done = (await self.session.execute(done_stmt)).scalar() or 0
        retention = (done / total) if total else 0.0

        consistency = min(streak / 30.0, 1.0)

        weak_avg = sum(t.mastery for t in weak) / len(weak) if weak else 0.0
        weak_score = max(0.0, 1.0 - weak_avg)

        breakdown = ReadinessBreakdown(
            knowledge=round(knowledge, 3),
            practice=round(practice, 3),
            retention=round(retention, 3),
            consistency=round(consistency, 3),
            weak_topics=round(weak_score, 3),
        )
        overall = (
            knowledge * 0.25
            + practice * 0.25
            + retention * 0.20
            + consistency * 0.15
            + weak_score * 0.15
        ) * 100
        return int(round(overall)), breakdown
