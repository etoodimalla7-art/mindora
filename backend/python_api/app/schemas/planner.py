"""Planner schemas — request and response DTOs."""
from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field


class ExamPlanCreate(BaseModel):
    exam_system: str = Field(min_length=1, max_length=32)
    exam_level: str = Field(min_length=1, max_length=32)
    exam_name: str = Field(min_length=1, max_length=120)
    subjects: list[str] = Field(min_length=1)
    target_date: date
    daily_minutes: int = Field(default=60, ge=15, le=600)
    start_date: date | None = None


class SubjectPlanCreate(BaseModel):
    subject: str = Field(min_length=1, max_length=80)
    topic: str | None = Field(default=None, max_length=160)
    duration_days: int = Field(ge=1, le=365)
    daily_minutes: int = Field(default=60, ge=15, le=600)
    start_date: date | None = None
    target_date: date | None = None


class StudySessionOut(BaseModel):
    id: uuid.UUID
    plan_id: uuid.UUID | None
    title: str
    subject: str | None
    topic: str | None
    objective: str | None
    scheduled_for: datetime
    duration_minutes: int
    status: str
    started_at: datetime | None
    completed_at: datetime | None

    class Config:
        from_attributes = True


class StudyPlanOut(BaseModel):
    id: uuid.UUID
    plan_type: str
    title: str
    subject: str | None
    exam_system: str | None
    exam_level: str | None
    exam_name: str | None
    start_date: date
    target_date: date | None
    daily_minutes: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class StudyPlanDetail(StudyPlanOut):
    sessions: list[StudySessionOut] = Field(default_factory=list)


class SessionCompleteRequest(BaseModel):
    confidence_after: float | None = Field(default=None, ge=0.0, le=1.0)
    notes: str | None = None
