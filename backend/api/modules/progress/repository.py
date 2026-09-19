from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.progress.models import Progress, ReadinessScore


class ProgressRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_subjects(self, user_id: str) -> list[Progress]:
        result = await self.db.execute(
            select(Progress).where(Progress.user_id == to_uuid(user_id)).order_by(Progress.mastery_score)
        )
        return list(result.scalars().all())

    async def get_latest_readiness(self, user_id: str, target_exam_name: str) -> ReadinessScore | None:
        result = await self.db.execute(
            select(ReadinessScore)
            .where(ReadinessScore.user_id == to_uuid(user_id))
            .where(ReadinessScore.target_exam_name == target_exam_name)
            .order_by(ReadinessScore.computed_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()
