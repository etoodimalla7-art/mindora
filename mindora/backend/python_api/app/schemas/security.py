"""Pydantic schemas for Security & Monitoring (Phase 7.1)."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


# ---------- System Health ----------


class ServiceStatus(BaseModel):
    name: str
    status: str  # "ok" | "degraded" | "down"
    latency_ms: float | None = None
    detail: str | None = None


class SystemHealthOut(BaseModel):
    overall: str  # "ok" | "degraded" | "down"
    timestamp: datetime
    services: list[ServiceStatus]
    uptime_seconds: float | None = None
    version: str | None = None
    env: str | None = None


# ---------- Metrics ----------


class SystemMetricsOut(BaseModel):
    total_users: int
    active_sessions_24h: int
    requests_per_minute: int
    failed_logins_24h: int
    unacknowledged_alerts: int
    database_size_mb: float | None = None
    updated_at: datetime


# ---------- Login History ----------


class LoginHistoryRow(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID | None
    email: str
    ip: str | None
    user_agent: str | None
    success: bool
    failure_reason: str | None
    created_at: datetime


class LoginHistoryListOut(BaseModel):
    items: list[LoginHistoryRow]
    total: int
    limit: int
    offset: int


# ---------- Security Alerts ----------


class SecurityAlertOut(BaseModel):
    id: uuid.UUID
    type: str
    severity: str
    message: str
    metadata: dict = Field(default_factory=dict)
    acknowledged: bool
    acknowledged_by: uuid.UUID | None
    acknowledged_at: datetime | None
    created_at: datetime


class AlertListOut(BaseModel):
    items: list[SecurityAlertOut]
    total: int
    unacknowledged: int


class AlertAckOut(BaseModel):
    id: uuid.UUID
    acknowledged: bool
    acknowledged_at: datetime


class AlertCreate(BaseModel):
    type: str = Field(default="manual", max_length=40)
    severity: str = Field(default="medium", pattern=r"^(low|medium|high|critical)$")
    message: str = Field(min_length=3, max_length=5000)
    metadata: dict = Field(default_factory=dict)
