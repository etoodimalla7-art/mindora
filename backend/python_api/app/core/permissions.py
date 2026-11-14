"""Granular permissions for MINDORA admin (Phase 1.2 RBAC).

Permissions follow `<resource>.<action>` convention.
Roles are aggregates of permissions.
"""
from __future__ import annotations

from enum import StrEnum


class Permission(StrEnum):
    # Users
    USERS_READ = "users.read"
    USERS_UPDATE = "users.update"
    USERS_SUSPEND = "users.suspend"
    USERS_DELETE = "users.delete"
    USERS_MANAGE_ROLES = "users.manage_roles"

    # Documents
    DOCUMENTS_READ = "documents.read"
    DOCUMENTS_UPLOAD = "documents.upload"
    DOCUMENTS_APPROVE = "documents.approve"
    DOCUMENTS_REJECT = "documents.reject"
    DOCUMENTS_DELETE = "documents.delete"
    MODERATION_MANAGE = "moderation.manage"

    # AI
    AI_READ = "ai.read"
    AI_CONFIGURE = "ai.configure"

    # Content
    CONTENT_MANAGE = "content.manage"
    NOTIFICATIONS_MANAGE = "notifications.manage"

    # Analytics
    ANALYTICS_READ = "analytics.read"
    ANALYTICS_EXPORT = "analytics.export"

    # Support
    SUPPORT_READ = "support.read"
    SUPPORT_WRITE = "support.write"
    SUPPORT_ASSIGN = "support.assign"

    # System
    SYSTEM_MANAGE = "system.manage"
    AUDIT_READ = "audit.read"


class RoleName(StrEnum):
    SUPER_ADMIN = "super_admin"
    ADMIN = "admin"
    MODERATOR = "moderator"
    SUPPORT = "support"
    ANALYST = "analyst"


# Role → permissions mapping
# This is the source of truth for default role permissions.
# Admins can grant/revoke individual permissions via UserRole overrides.
ROLE_PERMISSIONS: dict[RoleName, set[Permission]] = {
    RoleName.SUPER_ADMIN: {p for p in Permission},  # all
    RoleName.ADMIN: {
        Permission.SUPPORT_READ,
        Permission.SUPPORT_WRITE,
        Permission.SUPPORT_ASSIGN,
        Permission.USERS_READ,
        Permission.USERS_UPDATE,
        Permission.USERS_SUSPEND,
        Permission.DOCUMENTS_READ,
        Permission.DOCUMENTS_UPLOAD,
        Permission.DOCUMENTS_APPROVE,
        Permission.DOCUMENTS_REJECT,
        Permission.MODERATION_MANAGE,
        Permission.AI_READ,
        Permission.CONTENT_MANAGE,
        Permission.NOTIFICATIONS_MANAGE,
        Permission.ANALYTICS_READ,
        Permission.ANALYTICS_EXPORT,
        Permission.AUDIT_READ,
    },
    RoleName.MODERATOR: {
        Permission.DOCUMENTS_READ,
        Permission.DOCUMENTS_APPROVE,
        Permission.DOCUMENTS_REJECT,
        Permission.MODERATION_MANAGE,
    },
    RoleName.SUPPORT: {
        Permission.USERS_READ,
        Permission.DOCUMENTS_READ,
        Permission.AI_READ,
        Permission.SUPPORT_READ,
        Permission.SUPPORT_WRITE,
    },
    RoleName.ANALYST: {
        Permission.USERS_READ,
        Permission.DOCUMENTS_READ,
        Permission.AI_READ,
        Permission.ANALYTICS_READ,
        Permission.ANALYTICS_EXPORT,
        Permission.SUPPORT_READ,
    },
}


def has_permission(role_name: str, permission: Permission) -> bool:
    """Check if a role has a permission."""
    try:
        r = RoleName(role_name)
    except ValueError:
        return False
    return permission in ROLE_PERMISSIONS.get(r, set())
