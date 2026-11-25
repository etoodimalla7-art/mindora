"""Liveness and readiness endpoints."""
from __future__ import annotations

import redis.asyncio as aioredis
from fastapi import APIRouter
from sqlalchemy import text

from app.core.config import settings
from app.db.session import engine
from app.schemas.health import LivenessResponse, ReadinessChecks, ReadinessResponse

router = APIRouter()


@router.get("", response_model=LivenessResponse)
async def liveness() -> LivenessResponse:
    return LivenessResponse(
        app=settings.APP_NAME,
        version=settings.APP_VERSION,
        env=settings.APP_ENV,
    )


@router.get("/ready", response_model=ReadinessResponse)
async def readiness() -> ReadinessResponse:
    db_ok = False
    redis_ok = False

    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        db_ok = False

    try:
        client = aioredis.from_url(settings.REDIS_URL)
        await client.ping()
        await client.aclose()
        redis_ok = True
    except Exception:
        redis_ok = False

    status = "ready" if (db_ok and redis_ok) else "degraded"
    return ReadinessResponse(status=status, checks=ReadinessChecks(database=db_ok, redis=redis_ok))
