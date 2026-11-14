"""Pydantic schemas for AI Control Center (Phase 4)."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class AIConfigOut(BaseModel):
    id: uuid.UUID
    name: str
    system_prompt: str
    model: str
    temperature: float
    max_tokens: int
    language: str
    is_active: bool
    updated_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class AIConfigUpdate(BaseModel):
    system_prompt: str | None = Field(default=None, min_length=20, max_length=10000)
    model: str | None = Field(default=None, max_length=80)
    temperature: float | None = Field(default=None, ge=0.0, le=2.0)
    max_tokens: int | None = Field(default=None, ge=50, le=8000)
    language: str | None = Field(default=None, max_length=8)


class AIVersionOut(BaseModel):
    id: uuid.UUID
    config_id: uuid.UUID
    version: int
    system_prompt: str
    model: str
    temperature: float
    max_tokens: int
    notes: str | None
    published_by: uuid.UUID | None
    published_at: datetime

    class Config:
        from_attributes = True


class AIPublishRequest(BaseModel):
    notes: str | None = Field(default=None, max_length=500)


class AITestRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    system_prompt: str | None = None
    model: str | None = None
    temperature: float | None = None
    max_tokens: int | None = None


class AITestResponse(BaseModel):
    response: str
    model: str
    provider: str
    usage: dict = Field(default_factory=dict)
    elapsed_ms: int
