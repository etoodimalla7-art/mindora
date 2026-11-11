"""Pydantic schemas for Study Groups (Phase 13)."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class StudyGroupCreate(BaseModel):
    name: str = Field(min_length=3, max_length=120)
    description: str | None = Field(default=None, max_length=1000)
    exam_system: str | None = Field(default=None, max_length=40)
    exam_level: str | None = Field(default=None, max_length=40)
    subject: str | None = Field(default=None, max_length=80)
    is_private: bool = False


class StudyGroupOut(BaseModel):
    id: uuid.UUID
    name: str
    description: str | None
    exam_system: str | None
    exam_level: str | None
    subject: str | None
    creator_id: uuid.UUID
    is_private: bool
    member_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class GroupMessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)


class GroupMessageOut(BaseModel):
    id: uuid.UUID
    group_id: uuid.UUID
    user_id: uuid.UUID
    content: str
    created_at: datetime
    # Flattened user info for the UI
    user_name: str | None = None

    class Config:
        from_attributes = True
