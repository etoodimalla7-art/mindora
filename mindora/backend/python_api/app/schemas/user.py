"""User-facing schemas."""
from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, EmailStr, Field

from app.schemas.common import ORMModel


class ProfileOut(ORMModel):
    avatar_url: str | None = None
    bio: str | None = None
    timezone: str
    preferences: dict


class EducationProfileOut(ORMModel):
    education_system: str | None = None
    level: str | None = None
    program: str | None = None
    subjects: list = Field(default_factory=list)
    goals: list = Field(default_factory=list)
    study_preferences: dict = Field(default_factory=dict)
    target_exam_date: date | None = None


class UserOut(ORMModel):
    id: uuid.UUID
    email: EmailStr
    full_name: str | None = None
    preferred_language: str
    country_code: str
    is_active: bool
    is_verified: bool
    is_admin: bool
    created_at: datetime
    profile: ProfileOut | None = None
    education_profile: EducationProfileOut | None = None


class UserUpdate(BaseModel):
    full_name: str | None = Field(default=None, max_length=120)
    preferred_language: str | None = Field(default=None, max_length=8)
    country_code: str | None = Field(default=None, max_length=8)
