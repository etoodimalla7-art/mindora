"""Notification schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class DeviceRegisterRequest(BaseModel):
    fcm_token: str = Field(min_length=20, max_length=500)
    platform: str = Field(default="android", pattern="^(android|ios|web)$")
    device_model: str | None = Field(default=None, max_length=120)
    os_version: str | None = Field(default=None, max_length=40)
    app_version: str | None = Field(default=None, max_length=40)


class DeviceOut(BaseModel):
    id: uuid.UUID
    platform: str
    device_model: str | None = None
    notifications_enabled: bool
    last_seen_at: datetime | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationOut(BaseModel):
    id: uuid.UUID
    type: str
    title: str
    body: str
    deep_link: str | None = None
    status: str
    sent_at: datetime | None = None
    read_at: datetime | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class NotificationPreferenceOut(BaseModel):
    enabled: bool
    session_reminders: bool
    exam_countdown: bool
    streak_reminders: bool
    milestones: bool
    inactivity_nudges: bool
    weak_topic_alerts: bool
    max_per_day: int
    quiet_hours_start: int
    quiet_hours_end: int
    reminder_minutes_before: int
    timezone: str

    class Config:
        from_attributes = True


class NotificationPreferenceUpdate(BaseModel):
    enabled: bool | None = None
    session_reminders: bool | None = None
    exam_countdown: bool | None = None
    streak_reminders: bool | None = None
    milestones: bool | None = None
    inactivity_nudges: bool | None = None
    weak_topic_alerts: bool | None = None
    max_per_day: int | None = Field(default=None, ge=0, le=20)
    quiet_hours_start: int | None = Field(default=None, ge=0, le=23)
    quiet_hours_end: int | None = Field(default=None, ge=0, le=23)
    reminder_minutes_before: int | None = Field(default=None, ge=1, le=120)
    timezone: str | None = Field(default=None, max_length=64)


class TestNotificationRequest(BaseModel):
    """For testing — send a test notification to the current user."""

    title: str = Field(default="Test notification", max_length=200)
    body: str = Field(default="This is a test from MINDORA.", max_length=500)


# ---------------------------------------------------------------------------
# Admin — scheduler monitoring (12B.6)
# ---------------------------------------------------------------------------
from pydantic import BaseModel, Field  # noqa: E402


class JobInfoOut(BaseModel):
    """Information about a scheduled notification job."""

    id: str
    name: str
    trigger: str
    next_run_time: str | None = None


class TriggerJobOut(BaseModel):
    """Result of a manual job trigger."""

    job_id: str
    processed: int = Field(description="Number of users processed")
    message: str


class SchedulerHealthOut(BaseModel):
    """Scheduler status summary."""

    running: bool
    job_count: int
    provider: str
    jobs: list[JobInfoOut]
