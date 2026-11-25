"""Pydantic schemas for Session Management (Phase 7.3)."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel


class SessionRow(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    user_email: str | None
    is_admin: bool
    is_expired: bool
    expires_at: datetime
    created_at: datetime
    updated_at: datetime


class SessionListOut(BaseModel):
    items: list[SessionRow]
    total: int
    limit: int
    offset: int


class RevokeResultOut(BaseModel):
    revoked_count: int
    message: str


class CleanupResultOut(BaseModel):
    deleted_count: int
    message: str
