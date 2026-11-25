"""Health schemas."""
from __future__ import annotations

from typing import Literal

from pydantic import BaseModel


class LivenessResponse(BaseModel):
    status: Literal["ok"] = "ok"
    app: str
    version: str
    env: str


class ReadinessChecks(BaseModel):
    database: bool
    redis: bool


class ReadinessResponse(BaseModel):
    status: Literal["ready", "degraded"]
    checks: ReadinessChecks
