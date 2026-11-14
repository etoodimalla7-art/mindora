"""AI Control Center endpoints (Phase 4)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.schemas.admin_ai import (
    AIConfigOut,
    AIConfigUpdate,
    AIPublishRequest,
    AITestRequest,
    AITestResponse,
    AIVersionOut,
)
from app.services.ai_config_service import AIConfigService
from app.services.role_service import RoleService

router = APIRouter()


async def _require_ai_read(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.AI_READ)


async def _require_ai_configure(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.AI_CONFIGURE)


@router.get("/config", response_model=AIConfigOut)
async def get_config(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> AIConfigOut:
    await _require_ai_read(session, current_user_id)
    return await AIConfigService(session).get_active()


@router.patch("/config", response_model=AIConfigOut)
async def update_config(
    payload: AIConfigUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> AIConfigOut:
    await _require_ai_configure(session, current_user_id)
    return await AIConfigService(session).update(
        payload, updated_by=current_user_id
    )


@router.post("/config/publish", response_model=AIVersionOut)
async def publish_config(
    payload: AIPublishRequest,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> AIVersionOut:
    await _require_ai_configure(session, current_user_id)
    return await AIConfigService(session).publish(
        payload.notes, published_by=current_user_id
    )


@router.post("/config/test", response_model=AITestResponse)
async def test_config(
    payload: AITestRequest,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> AITestResponse:
    await _require_ai_configure(session, current_user_id)
    result = await AIConfigService(session).test(
        message=payload.message,
        system_prompt=payload.system_prompt,
        model=payload.model,
        temperature=payload.temperature,
        max_tokens=payload.max_tokens,
    )
    return AITestResponse(**result)


@router.get("/versions", response_model=list[AIVersionOut])
async def list_versions(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[AIVersionOut]:
    await _require_ai_read(session, current_user_id)
    return await AIConfigService(session).list_versions()


@router.post("/versions/{version_id}/activate", response_model=AIConfigOut)
async def activate_version(
    version_id: uuid.UUID,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> AIConfigOut:
    await _require_ai_configure(session, current_user_id)
    return await AIConfigService(session).activate_version(
        version_id, updated_by=current_user_id
    )
