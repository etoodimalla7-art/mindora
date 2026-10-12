"""Profile service."""
from __future__ import annotations

import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.models.user import User
from app.repositories.user_repo import UserRepository
from app.schemas.education import EducationProfileUpdate


class ProfileService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.users = UserRepository(session)

    async def get_me(self, user_id: uuid.UUID) -> User:
        user = await self.users.get_by_id(user_id)
        if not user:
            raise NotFoundError("Account not found.")
        return user

    async def update_education(
        self, user_id: uuid.UUID, payload: EducationProfileUpdate
    ) -> User:
        user = await self.get_me(user_id)
        await self.users.update_education_profile(
            user,
            education_system=payload.education_system,
            level=payload.level,
            program=payload.program,
            subjects=payload.subjects,
            goals=payload.goals,
            study_preferences=payload.study_preferences,
            target_exam_date=payload.target_exam_date,
        )
        await self.session.commit()
        await self.session.refresh(user)
        return user
