"""Admin DTOs — documents moderation, users management, papers, stats."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


# ===== Documents (existing) =====
class AdminDocumentRow(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    title: str
    owner_email: str
    status: str
    created_at: datetime


class ApproveResponse(BaseModel):
    id: uuid.UUID
    status: str


class RejectRequest(BaseModel):
    reason: str = Field(min_length=3, max_length=500)


class RejectResponse(BaseModel):
    id: uuid.UUID
    status: str
    reason: str


# ===== Stats dashboard =====
class UsersStats(BaseModel):
    total: int
    active: int
    admins: int
    new_this_week: int


class DocumentsStats(BaseModel):
    total: int
    pending: int
    approved: int


class PapersStats(BaseModel):
    total: int
    published: int
    draft: int


class ActivityStats(BaseModel):
    sessions_today: int
    uploads_today: int


class AdminStatsOut(BaseModel):
    users: UsersStats
    documents: DocumentsStats
    papers: PapersStats
    activity: ActivityStats


# ===== Users management =====
class AdminUserRow(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    email: str
    full_name: str | None
    is_active: bool
    is_verified: bool
    is_admin: bool
    created_at: datetime
    last_login_at: datetime | None = None


class ToggleActiveResponse(BaseModel):
    id: uuid.UUID
    is_active: bool


class PromoteResponse(BaseModel):
    id: uuid.UUID
    is_admin: bool


# ===== Papers =====
class PaperRow(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    title: str
    subject: str
    exam_system: str
    exam_level: str
    exam_year: int | None
    language: str
    status: str
    file_name: str
    file_size: int
    mime_type: str
    download_count: int
    created_at: datetime


class PaperDetail(PaperRow):
    description: str | None = None
    uploader_id: uuid.UUID | None = None
