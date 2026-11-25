"""Read-only audit log endpoints (permission: audit.read)."""
from __future__ import annotations

import uuid
from datetime import datetime

from fastapi import APIRouter, Query
from pydantic import BaseModel

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.services.audit_service import AuditService
from app.services.role_service import RoleService

router = APIRouter()


class AuditLogOut(BaseModel):
    id: uuid.UUID
    admin_id: uuid.UUID | None
    admin_email: str | None
    action: str
    resource_type: str | None
    resource_id: uuid.UUID | None
    ip_address: str | None
    result: str
    error: str | None
    created_at: datetime

    class Config:
        from_attributes = True


@router.get("/audit-logs", response_model=list[AuditLogOut])
async def list_audit_logs(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    admin_id: uuid.UUID | None = Query(default=None),
    action: str | None = Query(default=None, max_length=80),
    resource_type: str | None = Query(default=None, max_length=60),
    since: datetime | None = Query(default=None),
    until: datetime | None = Query(default=None),
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
) -> list[AuditLogOut]:
    # Permission check
    await RoleService(session).require_permission(
        current_user_id, Permission.AUDIT_READ
    )
    logs = await AuditService(session).list_logs(
        admin_id=admin_id,
        action=action,
        resource_type=resource_type,
        since=since,
        until=until,
        limit=limit,
        offset=offset,
    )
    return [AuditLogOut.model_validate(log) for log in logs]
