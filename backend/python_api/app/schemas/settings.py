"""Pydantic schemas for App Settings (Phase 7.2)."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


# ---------- App Setting ----------


class AppSettingOut(BaseModel):
    key: str
    value: Any  # JSONB — peut être str, list, dict, int, bool, null
    description: str | None
    updated_by: uuid.UUID | None
    updated_at: datetime

    class Config:
        from_attributes = True


class AppSettingUpdate(BaseModel):
    value: Any = Field(..., description="Nouvelle valeur (tout type JSON)")


# ---------- Feature Flag ----------


class FeatureFlagOut(BaseModel):
    key: str
    enabled: bool
    description: str | None
    updated_by: uuid.UUID | None
    updated_at: datetime

    class Config:
        from_attributes = True


class FeatureFlagUpdate(BaseModel):
    enabled: bool


# ---------- Maintenance ----------


class MaintenanceOut(BaseModel):
    enabled: bool
    message: str = ""
    eta: datetime | None = None


class MaintenanceUpdate(BaseModel):
    enabled: bool
    message: str = Field(default="", max_length=500)
    eta: datetime | None = None


# ---------- Aggregated (pour le frontend) ----------


class SettingsOptionsOut(BaseModel):
    """Tout ce dont le frontend a besoin en 1 call."""

    identity: dict[str, Any]  # name, tagline, logo_url, primary_color
    languages: dict[str, Any]  # default, active
    education_systems: list[str]
    subjects: list[str]
    levels: list[str]
    years: list[int]
    maintenance: MaintenanceOut
    feature_flags: list[FeatureFlagOut]

# ---------- Public Maintenance (no auth) ----------


class MaintenancePublicOut(BaseModel):
    """Public maintenance info — no sensitive data."""

    enabled: bool
    message: str = ""
    eta: datetime | None = None
