"""Admin Session Management endpoints (Phase 7.3).

⚠️ ORDRE : routes spécifiques AVANT /{session_id} et /users/{uid}
pour éviter les conflits de matching.
"""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.schemas.sessions import (
    CleanupResultOut,
    RevokeResultOut,
    SessionListOut,
)
from app.services.role_service import RoleService
from app.services.session_service import SessionService

router = APIRouter()


async def _require_users_read(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.USERS_READ)


async def _require_system_manage(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.SYSTEM_MANAGE)


# ---------- List ----------


@router.get("/sessions", response_model=SessionListOut)
async def list_sessions(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    user_id: uuid.UUID | None = Query(default=None),
    email: str | None = Query(default=None),
    admin_only: bool = Query(default=False),
    include_expired: bool = Query(default=False),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> SessionListOut:
    await _require_users_read(session, current_user_id)
    return await SessionService(session).list_sessions(
        user_id=user_id,
        email=email,
        admin_only=admin_only,
        include_expired=include_expired,
        limit=limit,
        offset=offset,
    )


# ---------- Cleanup (before /{session_id}) ----------


@router.post("/sessions/cleanup", response_model=CleanupResultOut)
async def cleanup_sessions(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> CleanupResultOut:
    await _require_system_manage(session, current_user_id)
    n = await SessionService(session).cleanup_expired()
    return CleanupResultOut(
        deleted_count=n,
        message=f"{n} session(s) expirée(s) supprimée(s)",
    )


# ---------- Revoke all sessions for a user ----------


@router.delete("/sessions/users/{user_id}", response_model=RevokeResultOut)
async def revoke_user_sessions(
    user_id: uuid.UUID,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> RevokeResultOut:
    await _require_system_manage(session, current_user_id)
    n = await SessionService(session).revoke_user_sessions(user_id)
    return RevokeResultOut(
        revoked_count=n,
        message=f"{n} session(s) révoquée(s) pour cet utilisateur",
    )


# ---------- Revoke 1 session ----------


@router.delete("/sessions/{session_id}", response_model=RevokeResultOut)
async def revoke_session(
    session_id: uuid.UUID,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> RevokeResultOut:
    await _require_system_manage(session, current_user_id)
    n = await SessionService(session).revoke_session(session_id)
    return RevokeResultOut(
        revoked_count=n,
        message=f"{n} session révoquée",
    )
