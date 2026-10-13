"""Credit and download schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class CreditEntryOut(BaseModel):
    id: uuid.UUID
    delta: int
    reason: str
    reference_id: uuid.UUID | None = None
    reference_type: str | None = None
    notes: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class CreditBalanceOut(BaseModel):
    balance: int
    signup_bonus: int
    contribution_reward: int
    download_cost: int
    history: list[CreditEntryOut] = Field(default_factory=list)


class DownloadOut(BaseModel):
    id: uuid.UUID
    document_id: uuid.UUID
    credits_spent: int
    downloaded_at: datetime
    size_bytes: int

    class Config:
        from_attributes = True


class DownloadResponse(BaseModel):
    download: DownloadOut
    remaining_balance: int
