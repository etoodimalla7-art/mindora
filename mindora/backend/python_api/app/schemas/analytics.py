"""Analytics Pydantic schemas — Phase 6.1.

DTOs for advanced analytics: retention cohorts, engagement funnel, CSV export.
"""
from __future__ import annotations

import re
import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field, field_validator

ALLOWED_ANALYTICS_EVENT_TYPES: frozenset[str] = frozenset(
    {
        "app_open",
        "screen_view",
        "signup_completed",
        "onboarding_completed",
        "study_session_started",
        "study_session_completed",
        "flashcard_deck_created",
        "flashcard_reviewed",
        "mock_exam_started",
        "mock_exam_submitted",
        "ai_tutor_message_sent",
        "paper_viewed",
        "paper_downloaded",
        "subscription_checkout_started",
        "subscription_activated",
        "support_ticket_created",
    }
)

_FORBIDDEN_RGPD_KEYS: frozenset[str] = frozenset(
    {
        "message",
        "prompt",
        "conversation",
        "conversation_text",
        "content",
        "body",
        "answer",
        "password",
        "email",
        "phone",
        "token",
        "secret",
        "otp",
        "authorization",
        "full_name",
    }
)
_EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")


def _validate_rgpd_metadata(obj: Any) -> None:
    if isinstance(obj, dict):
        for k, v in obj.items():
            key_norm = str(k).strip().lower()
            if key_norm in _FORBIDDEN_RGPD_KEYS:
                raise ValueError(
                    f"Champ metadata interdit par la politique RGPD : '{k}'."
                )
            _validate_rgpd_metadata(v)
    elif isinstance(obj, list):
        if len(obj) > 50:
            raise ValueError("Liste metadata trop longue (max 50).")
        for item in obj:
            _validate_rgpd_metadata(item)
    elif isinstance(obj, str):
        if len(obj) > 256:
            raise ValueError("Valeur texte metadata trop longue (max 256).")
        if _EMAIL_RE.search(obj):
            raise ValueError("Adresse email interdite dans metadata analytics.")


class AnalyticsEventCreate(BaseModel):
    event_type: str = Field(..., min_length=2, max_length=64)
    metadata: dict[str, Any] = Field(default_factory=dict)
    session_id: str | None = Field(default=None, max_length=128)
    platform: str | None = Field(default=None, pattern=r"^(android|ios|web)$")
    app_version: str | None = Field(default=None, max_length=32)
    occurred_at: datetime | None = None

    @field_validator("event_type")
    @classmethod
    def check_event_type(cls, v: str) -> str:
        norm = v.strip()
        if norm not in ALLOWED_ANALYTICS_EVENT_TYPES:
            raise ValueError(
                f"Type d'événement non autorisé : '{v}'. Autorisés: {sorted(ALLOWED_ANALYTICS_EVENT_TYPES)}"
            )
        return norm

    @field_validator("metadata")
    @classmethod
    def check_metadata_rgpd(cls, v: dict[str, Any]) -> dict[str, Any]:
        if len(v) > 30:
            raise ValueError("Trop de clés dans metadata (max 30).")
        _validate_rgpd_metadata(v)
        return v


class AnalyticsEventOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID | None
    event_type: str
    metadata: dict[str, Any]
    session_id: str | None = None
    platform: str | None = None
    app_version: str | None = None
    occurred_at: datetime
    created_at: datetime


# ---------- Retention ----------


class CohortRow(BaseModel):
    """One weekly signup cohort + its retention curve."""

    cohort_week: str = Field(..., description="ISO week, e.g. '2026-W40'")
    cohort_size: int = Field(..., description="Users who signed up that week")
    retention: list[float] = Field(
        ...,
        description="% of cohort active at week 0, 1, 2, ... (index = weeks since signup)",
    )


class RetentionResponse(BaseModel):
    weeks: int
    cohorts: list[CohortRow]


# ---------- Funnel ----------


class FunnelStage(BaseModel):
    key: str = Field(..., description="stage identifier, e.g. 'verified'")
    label: str = Field(..., description="human-readable label")
    count: int = Field(..., description="users who reached this stage")
    conversion_from_prev: float = Field(
        ..., description="% conversion from previous stage (100.0 for first)"
    )
    conversion_from_start: float = Field(
        ..., description="% conversion from first stage"
    )


class FunnelResponse(BaseModel):
    days: int
    total_signups: int
    stages: list[FunnelStage]


# ---------- Export ----------


class ExportUserRow(BaseModel):
    """Single row for CSV export."""

    email: str
    created_at: str
    is_verified: bool
    role: str
    last_login_at: str | None = None
    exam_system: str | None = None
    academic_level: str | None = None
