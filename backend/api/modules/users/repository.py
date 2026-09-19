from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.users.models import EducationProfile


class UsersRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_education_profile(self, user_id: str) -> EducationProfile | None:
        result = await self.db.execute(
            select(EducationProfile).where(EducationProfile.user_id == to_uuid(user_id))
        )
        return result.scalar_one_or_none()

    async def upsert_education_profile(self, user_id: str, data: dict) -> EducationProfile:
        existing = await self.get_education_profile(user_id)
        if existing:
            for key, value in data.items():
                setattr(existing, key, value)
            await self.db.commit()
            await self.db.refresh(existing)
            return existing
        profile = EducationProfile(user_id=to_uuid(user_id), **data)
        self.db.add(profile)
        await self.db.commit()
        await self.db.refresh(profile)
        return profile

    async def count_all(self) -> int:
        """Feeds admin analytics (Phase 16, section 66's lightweight
        platform-analytics scope)."""
        from sqlalchemy import func
        from api.modules.users.models import User
        result = await self.db.execute(select(func.count()).select_from(User))
        return result.scalar_one()
