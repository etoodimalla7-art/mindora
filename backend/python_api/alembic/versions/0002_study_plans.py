"""Study plans and study sessions.

Revision ID: 0002_study_plans
Revises: 0001_initial
Create Date: 2026-01-02
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0002_study_plans"
down_revision: Union[str, None] = "0001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "study_plans",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("plan_type", sa.String(16), nullable=False),
        sa.Column("title", sa.String(160), nullable=False),
        sa.Column("subject", sa.String(80), nullable=True),
        sa.Column("exam_system", sa.String(32), nullable=True),
        sa.Column("exam_level", sa.String(32), nullable=True),
        sa.Column("exam_name", sa.String(120), nullable=True),
        sa.Column("start_date", sa.Date, nullable=False),
        sa.Column("target_date", sa.Date, nullable=True),
        sa.Column("daily_minutes", sa.Integer, nullable=False, server_default="60"),
        sa.Column(
            "metadata_json",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_study_plans_user_id", "study_plans", ["user_id"])

    op.create_table(
        "study_sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "plan_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("study_plans.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("title", sa.String(160), nullable=False),
        sa.Column("subject", sa.String(80), nullable=True),
        sa.Column("topic", sa.String(160), nullable=True),
        sa.Column("objective", sa.Text, nullable=True),
        sa.Column("scheduled_for", sa.DateTime(timezone=True), nullable=False),
        sa.Column("duration_minutes", sa.Integer, nullable=False, server_default="45"),
        sa.Column("status", sa.String(16), nullable=False, server_default="scheduled"),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "metadata_json",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_study_sessions_user_id", "study_sessions", ["user_id"])
    op.create_index("ix_study_sessions_plan_id", "study_sessions", ["plan_id"])
    op.create_index(
        "ix_study_sessions_scheduled_for", "study_sessions", ["scheduled_for"]
    )


def downgrade() -> None:
    op.drop_index("ix_study_sessions_scheduled_for", table_name="study_sessions")
    op.drop_index("ix_study_sessions_plan_id", table_name="study_sessions")
    op.drop_index("ix_study_sessions_user_id", table_name="study_sessions")
    op.drop_table("study_sessions")
    op.drop_index("ix_study_plans_user_id", table_name="study_plans")
    op.drop_table("study_plans")
