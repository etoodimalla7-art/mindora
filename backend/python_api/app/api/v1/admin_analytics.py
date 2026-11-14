"""Analytics endpoints for admin dashboard."""
from __future__ import annotations

from fastapi import APIRouter, Query
from fastapi.responses import StreamingResponse

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.services.analytics_service import AnalyticsService
from app.services.role_service import RoleService

router = APIRouter()


async def _ensure_analytics_permission(
    session: SessionDep, current_user_id: CurrentUserId
) -> None:
    await RoleService(session).require_permission(
        current_user_id, Permission.ANALYTICS_READ
    )


async def _ensure_export_permission(
    session: SessionDep, current_user_id: CurrentUserId
) -> None:
    await RoleService(session).require_permission(
        current_user_id, Permission.ANALYTICS_EXPORT
    )


# ---------- Existing routes (unchanged) ----------


@router.get("/analytics/overview")
async def overview(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> dict:
    await _ensure_analytics_permission(session, current_user_id)
    return await AnalyticsService(session).overview()


@router.get("/analytics/users-timeseries")
async def users_timeseries(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    days: int = Query(default=7, ge=1, le=90),
) -> list[dict]:
    await _ensure_analytics_permission(session, current_user_id)
    return await AnalyticsService(session).users_timeseries(days)


@router.get("/analytics/documents-timeseries")
async def documents_timeseries(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    days: int = Query(default=7, ge=1, le=90),
) -> list[dict]:
    await _ensure_analytics_permission(session, current_user_id)
    return await AnalyticsService(session).documents_timeseries(days)


@router.get("/analytics/subjects-breakdown")
async def subjects_breakdown(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[dict]:
    await _ensure_analytics_permission(session, current_user_id)
    return await AnalyticsService(session).subjects_breakdown()


@router.get("/analytics/exam-systems-breakdown")
async def exam_systems_breakdown(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[dict]:
    await _ensure_analytics_permission(session, current_user_id)
    return await AnalyticsService(session).exam_systems_breakdown()


@router.get("/analytics/recent-activity")
async def recent_activity(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    limit: int = Query(default=20, ge=1, le=100),
) -> list[dict]:
    await _ensure_analytics_permission(session, current_user_id)
    return await AnalyticsService(session).recent_activity(limit)


# ---------- NEW — Phase 6.1 ----------


@router.get("/analytics/retention")
async def retention(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    weeks: int = Query(default=8, ge=1, le=26),
) -> dict:
    """Weekly signup cohort retention curves.

    Returns: { "weeks": int, "cohorts": [CohortRow...] }
    """
    await _ensure_analytics_permission(session, current_user_id)
    cohorts = await AnalyticsService(session).retention_cohorts(weeks)
    return {"weeks": weeks, "cohorts": cohorts}


@router.get("/analytics/funnel")
async def funnel(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    days: int = Query(default=30, ge=1, le=365),
) -> dict:
    """Engagement funnel (signup → verified → onboarding → chat → mock → paid)."""
    await _ensure_analytics_permission(session, current_user_id)
    return await AnalyticsService(session).engagement_funnel(days)


@router.get("/analytics/export/users.csv")
async def export_users_csv(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    verified: bool | None = Query(default=None),
    role: str | None = Query(default=None),
) -> StreamingResponse:
    """Stream users CSV. Permission: analytics.export."""
    await _ensure_export_permission(session, current_user_id)

    service = AnalyticsService(session)
    filters = {"verified": verified, "role": role}
    headers = {
        "Content-Disposition": 'attachment; filename="mindora-users.csv"',
        "Cache-Control": "no-store",
    }
    return StreamingResponse(
        service.export_users_csv(filters),
        media_type="text/csv",
        headers=headers,
    )
