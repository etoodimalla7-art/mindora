"""Pydantic schemas for RBAC."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class RoleOut(BaseModel):
    id: uuid.UUID
    name: str
    description: str | None
    default_permissions: list[str]
    is_system: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserRoleOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    role_id: uuid.UUID
    role_name: str
    extra_permissions: list[str]
    revoked_permissions: list[str]
    granted_at: datetime

    class Config:
        from_attributes = True


class AssignRoleRequest(BaseModel):
    role_name: str = Field(min_length=1, max_length=40)
    extra_permissions: list[str] = Field(default_factory=list)
    revoked_permissions: list[str] = Field(default_factory=list)


class UpdatePermissionsRequest(BaseModel):
    extra_permissions: list[str] = Field(default_factory=list)
    revoked_permissions: list[str] = Field(default_factory=list)
