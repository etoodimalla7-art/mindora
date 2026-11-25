"""Add dedup_key, priority, template_key to notifications.

Revision ID: 0010_notification_dedup
Revises: 0009_notifications
Create Date: 2026-10-15

"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "0010_notification_dedup"
down_revision = "0009_notifications"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add new columns (nullable initially to allow existing rows)
    op.add_column(
        "notifications",
        sa.Column("dedup_key", sa.String(length=200), nullable=True),
    )
    op.add_column(
        "notifications",
        sa.Column(
            "priority",
            sa.Integer(),
            nullable=False,
            server_default="3",
        ),
    )
    op.add_column(
        "notifications",
        sa.Column("template_key", sa.String(length=40), nullable=True),
    )

    # Widen status column (was String(20), model now String(30))
    op.alter_column(
        "notifications",
        "status",
        existing_type=sa.String(length=20),
        type_=sa.String(length=30),
        existing_nullable=False,
    )

    # Index on dedup_key alone (fast lookups)
    op.create_index(
        "ix_notifications_dedup_key",
        "notifications",
        ["dedup_key"],
        unique=False,
    )

    # Partial unique index: (user_id, dedup_key) unique where dedup_key IS NOT NULL
    op.create_index(
        "ix_notifications_user_dedup_unique",
        "notifications",
        ["user_id", "dedup_key"],
        unique=True,
        postgresql_where=sa.text("dedup_key IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("ix_notifications_user_dedup_unique", table_name="notifications")
    op.drop_index("ix_notifications_dedup_key", table_name="notifications")
    op.alter_column(
        "notifications",
        "status",
        existing_type=sa.String(length=30),
        type_=sa.String(length=20),
        existing_nullable=False,
    )
    op.drop_column("notifications", "template_key")
    op.drop_column("notifications", "priority")
    op.drop_column("notifications", "dedup_key")
