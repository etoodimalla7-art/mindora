from datetime import datetime
from pydantic import BaseModel, Field


class NotificationOut(BaseModel):
    id: str
    type: str
    title: str
    body: str
    scheduled_for: datetime
    read_at: datetime | None

    class Config:
        from_attributes = True


class NotificationPreferencesOut(BaseModel):
    enabled: bool
    quiet_hours_start: int
    quiet_hours_end: int
    preferred_study_times: list[str]

    class Config:
        from_attributes = True


class UpdateNotificationPreferencesIn(BaseModel):
    enabled: bool | None = None
    quiet_hours_start: int | None = Field(default=None, ge=0, le=23)
    quiet_hours_end: int | None = Field(default=None, ge=0, le=23)
    preferred_study_times: list[str] | None = None
