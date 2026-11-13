"""RBAC management endpoints (admin only)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Response, status

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.schemas.role import (
    AssignRoleRequest,
    RoleOut,
    UserRoleOut,
)
from app.services.role_service import RoleService

router = APIRouter()


@router.get("/roles", response_model=list[RoleOut])
async def list_roles(
    session: SessionDep, _admin: AdminUser
) -> list[RoleOut]:
    return await RoleService(session).list_roles()


@router.get("/users/{user_id}/roles", response_model=list[UserRoleOut])
async def get_user_roles(
    user_id: uuid.UUID,
    session: SessionDep,
    _admin: AdminUser,
) -> list[UserRoleOut]:
    return await RoleService(session).get_user_roles(user_id)


@router.get("/users/{user_id}/permissions", response_model=list[str])
async def get_user_permissions(
    user_id: uuid.UUID,
    session: SessionDep,
    _admin: AdminUser,
) -> list[str]:
    perms = await RoleService(session).get_effective_permissions(user_id)
    return sorted(perms)


@router.post("/users/{user_id}/roles", response_model=UserRoleOut)
async def assign_role(
    user_id: uuid.UUID,
    payload: AssignRoleRequest,
    session: SessionDep,
    admin: AdminUser,
    current_user_id: CurrentUserId,
) -> UserRoleOut:
    # Only super admins can assign roles
    svc = RoleService(session)
    await svc.require_permission(current_user_id, Permission.USERS_MANAGE_ROLES)
    return await svc.assign_role(
        user_id=user_id,
        role_name=payload.role_name,
        granted_by=current_user_id,
        payload=payload,
    )


@router.delete("/users/{user_id}/roles/{role_name}", status_code=204)
async def revoke_role(
    user_id: uuid.UUID,
    role_name: str,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> Response:
    svc = RoleService(session)
    await svc.require_permission(current_user_id, Permission.USERS_MANAGE_ROLES)
    await svc.revoke_role(user_id, role_name)
    return Response(status_code=204)
