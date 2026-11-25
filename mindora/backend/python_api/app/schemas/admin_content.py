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


# ---------- Subjects ----------


class SubjectCreate(BaseModel):
    slug: str = Field(min_length=2, max_length=80, pattern=r"^[a-z0-9_-]+$")
    name_fr: str = Field(min_length=2, max_length=160)
    name_en: str = Field(min_length=2, max_length=160)
    exam_systems: list[str] = Field(default_factory=list)
    display_order: int = Field(default=0, ge=0, le=1000)
    is_active: bool = True


class SubjectUpdate(BaseModel):
    name_fr: str | None = Field(default=None, min_length=2, max_length=160)
    name_en: str | None = Field(default=None, min_length=2, max_length=160)
    exam_systems: list[str] | None = None
    display_order: int | None = Field(default=None, ge=0, le=1000)
    is_active: bool | None = None


class SubjectOut(BaseModel):
    id: uuid.UUID
    slug: str
    name_fr: str
    name_en: str
    exam_systems: list[str]
    display_order: int
    is_active: bool
    deleted_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ---------- Chapters ----------


class ChapterCreate(BaseModel):
    subject_id: uuid.UUID
    title_fr: str = Field(min_length=2, max_length=200)
    title_en: str = Field(min_length=2, max_length=200)
    summary_fr: str | None = Field(default=None, max_length=3000)
    summary_en: str | None = Field(default=None, max_length=3000)
    level: str | None = Field(default=None, max_length=60)
    order_index: int = Field(default=0, ge=0, le=1000)
    is_published: bool = True


class ChapterUpdate(BaseModel):
    title_fr: str | None = Field(default=None, min_length=2, max_length=200)
    title_en: str | None = Field(default=None, min_length=2, max_length=200)
    summary_fr: str | None = Field(default=None, max_length=3000)
    summary_en: str | None = Field(default=None, max_length=3000)
    level: str | None = Field(default=None, max_length=60)
    order_index: int | None = Field(default=None, ge=0, le=1000)
    is_published: bool | None = None


class ChapterOut(BaseModel):
    id: uuid.UUID
    subject_id: uuid.UUID
    title_fr: str
    title_en: str
    summary_fr: str | None = None
    summary_en: str | None = None
    level: str | None = None
    order_index: int
    is_published: bool
    deleted_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ---------- Announcements ----------


class AnnouncementCreate(BaseModel):
    title_fr: str = Field(min_length=2, max_length=200)
    title_en: str = Field(min_length=2, max_length=200)
    body_fr: str = Field(min_length=2, max_length=5000)
    body_en: str = Field(min_length=2, max_length=5000)
    audience: str = Field(default="all", pattern=r"^(all|students|premium|free)$")
    priority: str = Field(default="normal", pattern=r"^(info|normal|urgent)$")
    is_published: bool = True
    starts_at: datetime | None = None
    ends_at: datetime | None = None


class AnnouncementUpdate(BaseModel):
    title_fr: str | None = Field(default=None, min_length=2, max_length=200)
    title_en: str | None = Field(default=None, min_length=2, max_length=200)
    body_fr: str | None = Field(default=None, min_length=2, max_length=5000)
    body_en: str | None = Field(default=None, min_length=2, max_length=5000)
    audience: str | None = Field(default=None, pattern=r"^(all|students|premium|free)$")
    priority: str | None = Field(default=None, pattern=r"^(info|normal|urgent)$")
    is_published: bool | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None


class AnnouncementOut(BaseModel):
    id: uuid.UUID
    title_fr: str
    title_en: str
    body_fr: str
    body_en: str
    audience: str
    priority: str
    is_published: bool
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    deleted_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
