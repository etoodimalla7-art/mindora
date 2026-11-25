"""User & profile repository."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.user import EducationProfile, Profile, User


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        stmt = (
            select(User)
            .where(User.id == user_id, User.deleted_at.is_(None))
            .options(selectinload(User.profile), selectinload(User.education_profile))
        )
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        stmt = (
            select(User)
            .where(User.email == email.lower(), User.deleted_at.is_(None))
            .options(selectinload(User.profile), selectinload(User.education_profile))
        )
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def create(
        self,
        *,
        email: str,
        hashed_password: str,
        full_name: str | None,
        preferred_language: str,
        country_code: str,
    ) -> User:
        user = User(
            email=email.lower(),
            hashed_password=hashed_password,
            full_name=full_name,
            preferred_language=preferred_language,
            country_code=country_code,
        )
        user.profile = Profile()
        user.education_profile = EducationProfile()
        self.session.add(user)
        await self.session.flush()
        return user

    async def touch_last_login(self, user: User) -> None:
        user.last_login_at = datetime.now(UTC).date()
        await self.session.flush()

    async def update_education_profile(
        self,
        user: User,
        *,
        education_system: str | None,
        level: str | None,
        program: str | None,
        subjects: list | None,
        goals: list | None,
        study_preferences: dict | None,
        target_exam_date,
    ) -> EducationProfile:
        ep = user.education_profile or EducationProfile()
        if education_system is not None:
            ep.education_system = education_system
        if level is not None:
            ep.level = level
        if program is not None:
            ep.program = program
        if subjects is not None:
            ep.subjects = subjects
        if goals is not None:
            ep.goals = goals
        if study_preferences is not None:
            ep.study_preferences = study_preferences
        if target_exam_date is not None:
            ep.target_exam_date = target_exam_date
        if user.education_profile is None:
            user.education_profile = ep
            self.session.add(ep)
        await self.session.flush()
        return ep
