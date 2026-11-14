"""Pydantic schemas for CMS content + broadcast notifications (Phase 5)."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ContentStringOut(BaseModel):
    id: uuid.UUID
    key: str
    description: str | None
    value_fr: str
    value_en: str
    group: str
    updated_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class ContentStringUpdate(BaseModel):
    value_fr: str | None = None
    value_en: str | None = None
    description: str | None = None


class ContentStringCreate(BaseModel):
    key: str = Field(min_length=2, max_length=120, pattern=r"^[a-z0-9_.]+$")
    description: str | None = Field(default=None, max_length=255)
    value_fr: str = Field(default="", max_length=5000)
    value_en: str = Field(default="", max_length=5000)
    group: str = Field(default="general", max_length=60)


class BroadcastCreate(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    body: str = Field(min_length=3, max_length=2000)
    target_criteria: dict = Field(default_factory=dict)
    scheduled_at: datetime | None = None


class BroadcastOut(BaseModel):
    id: uuid.UUID
    title: str
    body: str
    target_criteria: dict
    scheduled_at: datetime | None
    sent_at: datetime | None
    sent_count: int
    created_at: datetime

    class Config:
        from_attributes = True
