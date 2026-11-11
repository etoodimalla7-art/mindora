"""Pydantic schemas for Direct 1-to-1 messaging (Phase 13.7)."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class DirectConversationCreate(BaseModel):
    peer_user_id: uuid.UUID


class DirectPeerOut(BaseModel):
    user_id: uuid.UUID
    full_name: str | None
    email: str
    avatar_url: str | None


class DirectConversationOut(BaseModel):
    id: uuid.UUID
    peer: DirectPeerOut
    last_message_at: datetime | None
    last_message_preview: str | None
    unread_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class DirectMessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=4000)


class DirectMessageOut(BaseModel):
    id: uuid.UUID
    conversation_id: uuid.UUID
    sender_id: uuid.UUID
    content: str
    created_at: datetime
    read_at: datetime | None
    sender_name: str | None = None

    class Config:
        from_attributes = True
