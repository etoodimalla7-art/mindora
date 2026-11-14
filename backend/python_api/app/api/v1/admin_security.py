"""Admin Security & Monitoring endpoints (Phase 7.1)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.schemas.security import (
    AlertAckOut,
    AlertCreate,
    AlertListOut,
    LoginHistoryListOut,
    SecurityAlertOut,
    SystemHealthOut,
    SystemMetricsOut,
)
from app.services.role_service import RoleService
from app.services.security_service import SecurityService

router = APIRouter()


async def _require_system_health(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.SYSTEM_HEALTH)


async def _require_security_read(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.SECURITY_READ)


async def _require_system_manage(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.SYSTEM_MANAGE)


# ---------- System ----------


@router.get("/system/health", response_model=SystemHealthOut)
async def system_health(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> SystemHealthOut:
    await _require_system_health(session, current_user_id)
    return await SecurityService(session).health()


@router.get("/system/metrics", response_model=SystemMetricsOut)
async def system_metrics(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> SystemMetricsOut:
    await _require_system_health(session, current_user_id)
    return await SecurityService(session).metrics()


# ---------- Login History ----------


@router.get("/security/login-history", response_model=LoginHistoryListOut)
async def login_history(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    success: bool | None = Query(default=None),
    email: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> LoginHistoryListOut:
    await _require_security_read(session, current_user_id)
    return await SecurityService(session).list_login_history(
        success=success, email=email, limit=limit, offset=offset
    )


# ---------- Alerts ----------


@router.get("/security/alerts", response_model=AlertListOut)
async def list_alerts(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    acknowledged: bool | None = Query(default=None),
    severity: str | None = Query(default=None),
    type: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> AlertListOut:
    await _require_security_read(session, current_user_id)
    return await SecurityService(session).list_alerts(
        acknowledged=acknowledged,
        severity=severity,
        alert_type=type,
        limit=limit,
        offset=offset,
    )


@router.post("/security/alerts", response_model=SecurityAlertOut, status_code=201)
async def create_alert(
    payload: AlertCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> SecurityAlertOut:
    await _require_system_manage(session, current_user_id)
    return await SecurityService(session).create_alert(payload, current_user_id)


@router.patch("/security/alerts/{alert_id}/acknowledge", response_model=AlertAckOut)
async def acknowledge_alert(
    alert_id: uuid.UUID,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> AlertAckOut:
    await _require_system_manage(session, current_user_id)
    return await SecurityService(session).acknowledge_alert(alert_id, current_user_id)
