"""Education profile schemas."""
from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field


class EducationProfileUpdate(BaseModel):
    education_system: str | None = Field(default=None, max_length=32)
    level: str | None = Field(default=None, max_length=32)
    program: str | None = Field(default=None, max_length=120)
    subjects: list[str] | None = None
    goals: list[str] | None = None
    study_preferences: dict | None = None
    target_exam_date: date | None = None
