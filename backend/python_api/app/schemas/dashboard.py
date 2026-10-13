"""Home dashboard response schemas."""
from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field


class ExamCountdown(BaseModel):
    exam_name: str
    target_date: date
    days_remaining: int


class TodayFocus(BaseModel):
    session_id: uuid.UUID | None = None
    title: str | None = None
    subject: str | None = None
    topic: str | None = None
    objective: str | None = None
    duration_minutes: int | None = None
    scheduled_for: datetime | None = None


class ReadinessBreakdown(BaseModel):
    knowledge: float = 0.0
    practice: float = 0.0
    retention: float = 0.0
    consistency: float = 0.0
    weak_topics: float = 0.0


class WeakTopic(BaseModel):
    subject: str
    topic: str
    mastery: float


class RecentActivity(BaseModel):
    session_id: uuid.UUID
    title: str
    subject: str | None = None
    completed_at: datetime | None = None
    duration_minutes: int


class DashboardResponse(BaseModel):
    greeting_name: str | None = None
    streak_days: int = 0
    exam_countdown: ExamCountdown | None = None
    today_focus: TodayFocus | None = None
    readiness_score: int = 0
    readiness_breakdown: ReadinessBreakdown = Field(default_factory=ReadinessBreakdown)
    weak_topics: list[WeakTopic] = Field(default_factory=list)
    recent_activity: list[RecentActivity] = Field(default_factory=list)
