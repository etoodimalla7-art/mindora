"""AI chat schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=8000)
    conversation_id: uuid.UUID | None = None
    subject: str | None = Field(default=None, max_length=80)

    # Optional context overrides — the UI can pass these to force
    # a specific behaviour (e.g. explain level).
    context_type: str | None = Field(default=None, max_length=40)
    context_id: uuid.UUID | None = None


class ToolUsage(BaseModel):
    name: str
    args: dict | None = None
    result_preview: str | None = None


class MessageOut(BaseModel):
    id: uuid.UUID
    role: str
    content: str
    tools_used: list[dict] = Field(default_factory=list)
    model: str | None = None
    provider: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class ConversationOut(BaseModel):
    id: uuid.UUID
    title: str
    subject: str | None = None
    message_count: int
    is_archived: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ConversationDetail(ConversationOut):
    messages: list[MessageOut] = Field(default_factory=list)


class ChatResponse(BaseModel):
    conversation_id: uuid.UUID
    message: MessageOut
    usage: dict = Field(default_factory=dict)


class IntentDecision(BaseModel):
    """Internal schema for the orchestrator's intent classifier."""

    intent: str
    confidence: float = Field(ge=0.0, le=1.0)
    tools: list[str] = Field(default_factory=list)
    reasoning: str | None = None
