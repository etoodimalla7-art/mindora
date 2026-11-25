"""RBAC service — roles, assignments, permission checks."""
from __future__ import annotations

import logging
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ForbiddenError, NotFoundError
from app.core.permissions import Permission, RoleName, has_permission
from app.models.role import Role, UserRole
from app.models.user import User
from app.schemas.role import AssignRoleRequest, RoleOut, UserRoleOut

logger = logging.getLogger(__name__)


class RoleService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_roles(self) -> list[RoleOut]:
        rows = (
            await self.session.execute(select(Role).order_by(Role.name))
        ).scalars().all()
        return [RoleOut.model_validate(r) for r in rows]

    async def get_user_roles(self, user_id: uuid.UUID) -> list[UserRoleOut]:
        rows = (
            await self.session.execute(
                select(UserRole).where(UserRole.user_id == user_id)
            )
        ).scalars().all()
        return [
            UserRoleOut(
                id=r.id,
                user_id=r.user_id,
                role_id=r.role_id,
                role_name=r.role.name if r.role else "",
                extra_permissions=r.extra_permissions or [],
                revoked_permissions=r.revoked_permissions or [],
                granted_at=r.granted_at,
            )
            for r in rows
        ]

    async def assign_role(
        self,
        *,
        user_id: uuid.UUID,
        role_name: str,
        granted_by: uuid.UUID,
        payload: AssignRoleRequest | None = None,
    ) -> UserRoleOut:
        # Verify user exists
        user = await self.session.get(User, user_id)
        if not user:
            raise NotFoundError("User not found.")

        # Verify role exists
        role = (
            await self.session.execute(
                select(Role).where(Role.name == role_name)
            )
        ).scalar_one_or_none()
        if not role:
            raise NotFoundError(f"Role '{role_name}' not found.")

        # Check if assignment already exists
        existing = (
            await self.session.execute(
                select(UserRole).where(
                    UserRole.user_id == user_id,
                    UserRole.role_id == role.id,
                )
            )
        ).scalar_one_or_none()

        extra = payload.extra_permissions if payload else []
        revoked = payload.revoked_permissions if payload else []

        if existing:
            existing.extra_permissions = extra
            existing.revoked_permissions = revoked
            await self.session.commit()
            await self.session.refresh(existing)
            return UserRoleOut(
                id=existing.id,
                user_id=existing.user_id,
                role_id=existing.role_id,
                role_name=role.name,
                extra_permissions=extra,
                revoked_permissions=revoked,
                granted_at=existing.granted_at,
            )

        ur = UserRole(
            user_id=user_id,
            role_id=role.id,
            extra_permissions=extra,
            revoked_permissions=revoked,
            granted_by=granted_by,
        )
        self.session.add(ur)
        await self.session.commit()
        await self.session.refresh(ur)
        return UserRoleOut(
            id=ur.id,
            user_id=ur.user_id,
            role_id=ur.role_id,
            role_name=role.name,
            extra_permissions=ur.extra_permissions or [],
            revoked_permissions=ur.revoked_permissions or [],
            granted_at=ur.granted_at,
        )

    async def revoke_role(self, user_id: uuid.UUID, role_name: str) -> None:
        role = (
            await self.session.execute(
                select(Role).where(Role.name == role_name)
            )
        ).scalar_one_or_none()
        if not role:
            raise NotFoundError(f"Role '{role_name}' not found.")
        ur = (
            await self.session.execute(
                select(UserRole).where(
                    UserRole.user_id == user_id,
                    UserRole.role_id == role.id,
                )
            )
        ).scalar_one_or_none()
        if ur:
            await self.session.delete(ur)
            await self.session.commit()

    async def get_effective_permissions(self, user_id: uuid.UUID) -> set[str]:
        """Compute the effective permission set for a user."""
        user = await self.session.get(User, user_id)
        if not user:
            return set()

        # Legacy: is_admin gives everything
        if user.is_admin:
            return {p.value for p in Permission}

        # RBAC: union of role permissions + extras - revoked
        result: set[str] = set()
        rows = (
            await self.session.execute(
                select(UserRole).where(UserRole.user_id == user_id)
            )
        ).scalars().all()

        for ur in rows:
            if ur.role:
                result.update(ur.role.default_permissions or [])
            result.update(ur.extra_permissions or [])

        for ur in rows:
            for p in (ur.revoked_permissions or []):
                result.discard(p)

        return result

    async def require_permission(
        self, user_id: uuid.UUID, permission: Permission
    ) -> None:
        """Raise ForbiddenError if the user does not have the permission."""
        perms = await self.get_effective_permissions(user_id)
        if permission.value not in perms:
            raise ForbiddenError(
                f"Permission '{permission.value}' required."
            )
