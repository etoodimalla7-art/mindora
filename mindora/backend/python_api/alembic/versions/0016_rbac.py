"""add RBAC (roles + user_roles)

Revision ID: 0016_rbac
Revises: 0015_direct_messages
Create Date: 2026-11-14
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB, UUID


revision = "0016_rbac"
down_revision = "0015_direct_messages"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # --- roles ---
    op.create_table(
        "roles",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(40), nullable=False),
        sa.Column("description", sa.String(255), nullable=True),
        sa.Column(
            "default_permissions",
            JSONB,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column(
            "is_system",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint("name", name="uq_roles_name"),
    )
    op.create_index("ix_roles_name", "roles", ["name"], unique=True)

    # --- user_roles ---
    op.create_table(
        "user_roles",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "role_id",
            UUID(as_uuid=True),
            sa.ForeignKey("roles.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "extra_permissions",
            JSONB,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column(
            "revoked_permissions",
            JSONB,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column(
            "granted_by",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "granted_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint("user_id", "role_id", name="uq_user_role"),
    )
    op.create_index("ix_user_roles_user_id", "user_roles", ["user_id"])
    op.create_index("ix_user_roles_role_id", "user_roles", ["role_id"])

    # --- seed system roles ---
    roles_table = sa.table(
        "roles",
        sa.column("id", UUID(as_uuid=True)),
        sa.column("name", sa.String),
        sa.column("description", sa.String),
        sa.column("default_permissions", JSONB),
        sa.column("is_system", sa.Boolean),
    )

    import uuid as _uuid
    from app.core.permissions import RoleName, ROLE_PERMISSIONS, Permission

    def perms_for(role: RoleName) -> list[str]:
        return sorted(p.value for p in ROLE_PERMISSIONS.get(role, set()))

    op.bulk_insert(roles_table, [
        {
            "id": _uuid.uuid4(),
            "name": RoleName.SUPER_ADMIN.value,
            "description": "Full system access",
            "default_permissions": perms_for(RoleName.SUPER_ADMIN),
            "is_system": True,
        },
        {
            "id": _uuid.uuid4(),
            "name": RoleName.ADMIN.value,
            "description": "Administrative operations",
            "default_permissions": perms_for(RoleName.ADMIN),
            "is_system": True,
        },
        {
            "id": _uuid.uuid4(),
            "name": RoleName.MODERATOR.value,
            "description": "Content moderation",
            "default_permissions": perms_for(RoleName.MODERATOR),
            "is_system": True,
        },
        {
            "id": _uuid.uuid4(),
            "name": RoleName.SUPPORT.value,
            "description": "User support",
            "default_permissions": perms_for(RoleName.SUPPORT),
            "is_system": True,
        },
        {
            "id": _uuid.uuid4(),
            "name": RoleName.ANALYST.value,
            "description": "Read-only analytics",
            "default_permissions": perms_for(RoleName.ANALYST),
            "is_system": True,
        },
    ])


def downgrade() -> None:
    op.drop_index("ix_user_roles_role_id", table_name="user_roles")
    op.drop_index("ix_user_roles_user_id", table_name="user_roles")
    op.drop_table("user_roles")
    op.drop_index("ix_roles_name", table_name="roles")
    op.drop_table("roles")
