"""Create user_progress table for server-calculated streaks and study metrics.

Revision ID: 0030_user_progress
Revises: 0029_analytics_events
Create Date: 2026-11-19
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0030_user_progress"
down_revision = "0029_analytics_events"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "user_progress",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("current_streak", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("longest_streak", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_xp", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_minutes", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("sessions_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("flashcards_reviewed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("exams_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_activity_date", sa.Date(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_user_progress_user_id", "user_progress", ["user_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_user_progress_user_id", table_name="user_progress")
    op.drop_table("user_progress")
