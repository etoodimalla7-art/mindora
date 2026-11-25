"""Add snapshot JSONB + language to ai_config_versions and active_version to ai_configs.

Revision ID: 0033_ai_config_snapshot
Revises: 0032_exam_read_requests
Create Date: 2026-11-19
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0033_ai_config_snapshot"
down_revision = "0032_exam_read_requests"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "ai_configs",
        sa.Column(
            "active_version",
            sa.Integer(),
            nullable=False,
            server_default="1",
        ),
    )
    op.add_column(
        "ai_config_versions",
        sa.Column(
            "language",
            sa.String(8),
            nullable=False,
            server_default="fr",
        ),
    )
    op.add_column(
        "ai_config_versions",
        sa.Column(
            "snapshot",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
    )

    op.execute(
        sa.text(
            """
            UPDATE ai_config_versions
            SET snapshot = jsonb_build_object(
                'system_prompt', system_prompt,
                'model', model,
                'temperature', temperature,
                'max_tokens', max_tokens,
                'language', language
            )
            WHERE snapshot = '{}'::jsonb
            """
        )
    )
    op.execute(
        sa.text(
            """
            UPDATE ai_configs c
            SET active_version = COALESCE(
                (SELECT MAX(v.version) FROM ai_config_versions v WHERE v.config_id = c.id),
                1
            )
            """
        )
    )


def downgrade() -> None:
    op.drop_column("ai_config_versions", "snapshot")
    op.drop_column("ai_config_versions", "language")
    op.drop_column("ai_configs", "active_version")
