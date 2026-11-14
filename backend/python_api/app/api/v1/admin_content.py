"""Admin Content CMS + broadcast endpoints (Phase 5)."""
from __future__ import annotations

from fastapi import APIRouter, Query

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.schemas.admin_content import (
    BroadcastCreate,
    BroadcastOut,
    ContentStringCreate,
    ContentStringOut,
    ContentStringUpdate,
)
from app.services.content_service import ContentService
from app.services.role_service import RoleService

router = APIRouter()


async def _require_content_manage(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.CONTENT_MANAGE)


async def _require_notif_manage(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.NOTIFICATIONS_MANAGE)


# ---------- Content strings ----------

@router.get("/content", response_model=list[ContentStringOut])
async def list_content(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    group: str | None = Query(default=None),
) -> list[ContentStringOut]:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).list_strings(group)


@router.get("/content/{key}", response_model=ContentStringOut)
async def get_content(
    key: str,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> ContentStringOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).get_string(key)


@router.post("/content", response_model=ContentStringOut, status_code=201)
async def create_content(
    payload: ContentStringCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> ContentStringOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).create_string(
        payload, updated_by=current_user_id
    )


@router.patch("/content/{key}", response_model=ContentStringOut)
async def update_content(
    key: str,
    payload: ContentStringUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> ContentStringOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).update_string(
        key, payload, updated_by=current_user_id
    )


# ---------- Broadcasts ----------

@router.get("/broadcasts", response_model=list[BroadcastOut])
async def list_broadcasts(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[BroadcastOut]:
    await _require_notif_manage(session, current_user_id)
    return await ContentService(session).list_broadcasts()


@router.post("/broadcasts", response_model=BroadcastOut, status_code=201)
async def create_broadcast(
    payload: BroadcastCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> BroadcastOut:
    await _require_notif_manage(session, current_user_id)
    return await ContentService(session).create_broadcast(
        payload, created_by=current_user_id
    )
