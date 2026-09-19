from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.study_sessions.models import StudySession


class StudySessionsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_today(self, user_id: str) -> list[StudySession]:
        now = datetime.now(timezone.utc)
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        result = await self.db.execute(
            select(StudySession)
            .where(StudySession.user_id == to_uuid(user_id))
            .where(StudySession.scheduled_at >= start)
            .where(StudySession.scheduled_at < end)
            .order_by(StudySession.scheduled_at)
        )
        return list(result.scalars().all())

    async def get_by_id(self, session_id: str, user_id: str) -> StudySession | None:
        result = await self.db.execute(
            select(StudySession)
            .where(StudySession.id == to_uuid(session_id))
            .where(StudySession.user_id == to_uuid(user_id))
        )
        return result.scalar_one_or_none()

    async def set_status(self, session: StudySession, status: str) -> StudySession:
        session.status = status
        await self.db.commit()
        await self.db.refresh(session)
        return session

    async def get_completed_dates(self, user_id: str, since_days: int = 60) -> list[datetime]:
        """Used by the progress module to compute the study streak."""
        cutoff = datetime.now(timezone.utc) - timedelta(days=since_days)
        result = await self.db.execute(
            select(StudySession.scheduled_at)
            .where(StudySession.user_id == to_uuid(user_id))
            .where(StudySession.status == "completed")
            .where(StudySession.scheduled_at >= cutoff)
            .order_by(StudySession.scheduled_at.desc())
        )
        return [row[0] for row in result.all()]

    async def get_upcoming_within(self, user_id: str, minutes: int) -> list[StudySession]:
        """Feeds notification generation (Phase 14): pending sessions
        starting within the next N minutes."""
        now = datetime.now(timezone.utc)
        window_end = now + timedelta(minutes=minutes)
        result = await self.db.execute(
            select(StudySession)
            .where(StudySession.user_id == to_uuid(user_id))
            .where(StudySession.status == "pending")
            .where(StudySession.scheduled_at >= now)
            .where(StudySession.scheduled_at <= window_end)
        )
        return list(result.scalars().all())

    async def get_missed(self, user_id: str, grace_minutes: int = 60) -> list[StudySession]:
        """A session still 'pending' well after it was scheduled — the
        grace period avoids flagging a session as missed the moment
        it's a few minutes late."""
        cutoff = datetime.now(timezone.utc) - timedelta(minutes=grace_minutes)
        result = await self.db.execute(
            select(StudySession)
            .where(StudySession.user_id == to_uuid(user_id))
            .where(StudySession.status == "pending")
            .where(StudySession.scheduled_at <= cutoff)
        )
        return list(result.scalars().all())
