"""Analytics event ingestion endpoints (RGPD-safe telemetry)."""
from __future__ import annotations

from fastapi import APIRouter, status

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.analytics import AnalyticsEventCreate, AnalyticsEventOut
from app.services.analytics_service import AnalyticsService

router = APIRouter()


@router.post(
    "/events",
    response_model=AnalyticsEventOut,
    status_code=status.HTTP_201_CREATED,
)
async def ingest_analytics_event(
    payload: AnalyticsEventCreate,
    session: SessionDep,
    user_id: CurrentUserId,
) -> AnalyticsEventOut:
    """Record a validated telemetry event without PII or conversation text."""
    return await AnalyticsService(session).record_event(
        user_id=user_id,
        payload=payload,
    )
