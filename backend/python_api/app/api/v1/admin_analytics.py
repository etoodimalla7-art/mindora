"""Analytics endpoints for admin dashboard."""
from __future__ import annotations

from fastapi import APIRouter, Query

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
