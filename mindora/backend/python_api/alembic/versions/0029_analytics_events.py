"""Create analytics_events table for telemetry without PII.

Revision ID: 0029_analytics_events
Revises: 0028_support_ticket_fields
Create Date: 2026-11-19
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0029_analytics_events"
down_revision = "0028_support_ticket_fields"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "analytics_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("event_type", sa.String(64), nullable=False),
        sa.Column(
            "metadata",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("session_id", sa.String(128), nullable=True),
        sa.Column("platform", sa.String(32), nullable=True),
        sa.Column("app_version", sa.String(32), nullable=True),
        sa.Column(
            "occurred_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_analytics_events_event_type_occurred",
        "analytics_events",
        ["event_type", "occurred_at"],
    )
    op.create_index(
        "ix_analytics_events_user_occurred",
        "analytics_events",
        ["user_id", "occurred_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_analytics_events_user_occurred", table_name="analytics_events")
    op.drop_index("ix_analytics_events_event_type_occurred", table_name="analytics_events")
    op.drop_table("analytics_events")
