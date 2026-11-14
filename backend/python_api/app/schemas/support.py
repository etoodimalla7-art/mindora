"""Pydantic schemas for Support Center (Phase 6.2)."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


# ---------- Ticket ----------


class TicketCreate(BaseModel):
    subject: str = Field(min_length=3, max_length=255)
    description: str = Field(min_length=3, max_length=5000)
    priority: str = Field(default="normal", pattern=r"^(low|normal|high|urgent)$")
    # Optionnel : un admin peut créer un ticket au nom d'un user
    user_id: uuid.UUID | None = None


class TicketRow(BaseModel):
    """Row model for ticket listing."""

    id: uuid.UUID
    subject: str
    description: str
    status: str
    priority: str
    assigned_to: uuid.UUID | None
    user_id: uuid.UUID
    user_email: str | None
    assigned_to_email: str | None
    resolved_at: datetime | None
    created_at: datetime
    updated_at: datetime


class SupportMessageOut(BaseModel):
    id: uuid.UUID
    ticket_id: uuid.UUID
    author_id: uuid.UUID
    author_email: str | None
    body: str
    is_admin: bool
    created_at: datetime


class TicketDetailOut(TicketRow):
    messages: list[SupportMessageOut]


# ---------- Actions ----------


class TicketRespond(BaseModel):
    body: str = Field(min_length=1, max_length=5000)


class TicketAssign(BaseModel):
    assigned_to: uuid.UUID


class TicketStatusUpdate(BaseModel):
    status: str = Field(pattern=r"^(open|in_progress|resolved|closed)$")


# ---------- Stats ----------


class SupportStatsOut(BaseModel):
    total: int
    open: int
    in_progress: int
    resolved: int
    closed: int
    by_priority: dict[str, int] = Field(default_factory=dict)


# ---------- List response ----------


class TicketListOut(BaseModel):
    items: list[TicketRow]
    total: int
    limit: int
    offset: int
