"""Analytics Pydantic schemas — Phase 6.1.

DTOs for advanced analytics: retention cohorts, engagement funnel, CSV export.
"""
from __future__ import annotations

from pydantic import BaseModel, Field


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
