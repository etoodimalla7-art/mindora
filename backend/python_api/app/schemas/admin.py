"""Admin-only schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class AdminDocumentRow(BaseModel):
    id: uuid.UUID
    owner_id: uuid.UUID
    title: str
    original_filename: str
    mime_type: str
    size_bytes: int
    status: str
    quality_score: float
    category: str | None = None
    academic_level: str | None = None
    language: str
    created_at: datetime

    class Config:
        from_attributes = True


class RejectRequest(BaseModel):
    reason: str = Field(min_length=3, max_length=500)


class ApproveResponse(BaseModel):
    document_id: uuid.UUID
    status: str
    contributor_reward: int
    message: str


class RejectResponse(BaseModel):
    document_id: uuid.UUID
    status: str
    reason: str
    message: str
