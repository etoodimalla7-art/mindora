"""Topic progress.

Revision ID: 0003_topic_progress
Revises: 0002_study_plans
Create Date: 2026-01-02
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0003_topic_progress"
down_revision: Union[str, None] = "0002_study_plans"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "topic_progress",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("subject", sa.String(80), nullable=False),
        sa.Column("topic", sa.String(160), nullable=False),
        sa.Column("mastery", sa.Float, nullable=False, server_default="0"),
        sa.Column("confidence", sa.Float, nullable=False, server_default="0"),
        sa.Column("questions_seen", sa.Integer, nullable=False, server_default="0"),
        sa.Column("questions_correct", sa.Integer, nullable=False, server_default="0"),
        sa.Column("minutes_studied", sa.Integer, nullable=False, server_default="0"),
        sa.Column("last_reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "metadata_json",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint(
            "user_id",
            "subject",
            "topic",
            name="uq_topic_progress_user_subject_topic",
        ),
    )
    op.create_index("ix_topic_progress_user_id", "topic_progress", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_topic_progress_user_id", table_name="topic_progress")
    op.drop_table("topic_progress")
