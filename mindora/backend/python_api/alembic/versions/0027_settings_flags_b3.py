"""Add metadata/audit fields and extra default flags to app_settings & feature_flags.

Revision ID: 0027_settings_flags_b3
Revises: 0026_notification_rules
Create Date: 2026-11-19
"""
from __future__ import annotations

import json

import sqlalchemy as sa
from alembic import op

revision = "0027_settings_flags_b3"
down_revision = "0026_notification_rules"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "app_settings",
        sa.Column(
            "category",
            sa.String(40),
            nullable=False,
            server_default="general",
        ),
    )
    op.add_column(
        "app_settings",
        sa.Column(
            "is_public",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
    )
    op.add_column(
        "feature_flags",
        sa.Column(
            "rollout_percentage",
            sa.Integer(),
            nullable=False,
            server_default="100",
        ),
    )
    op.add_column(
        "feature_flags",
        sa.Column(
            "environment",
            sa.String(30),
            nullable=False,
            server_default="all",
        ),
    )

    extra_settings = [
        ("app.support_email", "support@mindora.dev", "Email support officiel", "general", True),
        ("app.min_supported_version", "1.0.0", "Version minimale mobile", "general", True),
        ("security.max_login_attempts", 5, "Tentatives max avant verrouillage", "security", False),
    ]
    for key, value, desc, category, is_public in extra_settings:
        op.execute(
            sa.text(
                """
                INSERT INTO app_settings (key, value, description, category, is_public)
                VALUES (:key, CAST(:value AS jsonb), :desc, :category, :is_public)
                ON CONFLICT (key) DO NOTHING
                """
            ).bindparams(
                key=key,
                value=json.dumps(value, ensure_ascii=False),
                desc=desc,
                category=category,
                is_public=is_public,
            )
        )

    extra_flags = [
        ("streak_gamification", True, "Gamification séries & XP"),
        ("offline_sync", True, "Mode hors-ligne et synchronisation"),
    ]
    for key, enabled, desc in extra_flags:
        op.execute(
            sa.text(
                """
                INSERT INTO feature_flags (key, enabled, description)
                VALUES (:key, :enabled, :desc)
                ON CONFLICT (key) DO NOTHING
                """
            ).bindparams(key=key, enabled=enabled, desc=desc)
        )


def downgrade() -> None:
    op.drop_column("feature_flags", "environment")
    op.drop_column("feature_flags", "rollout_percentage")
    op.drop_column("app_settings", "is_public")
    op.drop_column("app_settings", "category")
