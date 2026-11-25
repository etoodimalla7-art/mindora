"""add CMS content strings + broadcast notifications

Revision ID: 0021_cms_broadcast
Revises: 0020_ai_config
Create Date: 2026-11-14
"""
from __future__ import annotations

import uuid

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB, UUID


revision = "0021_cms_broadcast"
down_revision = "0020_ai_config"
branch_labels = None
depends_on = None


SEED_KEYS = [
    ("welcome_message", "Message d'accueil",
     "Bienvenue sur MINDORA !", "Welcome to MINDORA!", "onboarding"),
    ("tagline", "Tagline",
     "Ton tuteur académique IA", "Your AI academic tutor", "general"),
    ("maintenance_message", "Message de maintenance",
     "MINDORA est en maintenance. Reviens bientôt !",
     "MINDORA is under maintenance. Back soon!", "system"),
    ("announcement_banner", "Bannière d'annonce",
     "", "", "announcements"),
    ("terms_url", "URL des CGU",
     "https://mindora.dev/terms", "https://mindora.dev/terms", "legal"),
    ("privacy_url", "URL de la politique de confidentialité",
     "https://mindora.dev/privacy", "https://mindora.dev/privacy", "legal"),
    ("support_email", "Email de support",
     "support@mindora.dev", "support@mindora.dev", "system"),
    ("ai_welcome", "Message de bienvenue de l'IA",
     "Salut ! Je suis MINDORA, ton tuteur. Pose-moi une question.",
     "Hi! I'm MINDORA, your tutor. Ask me anything.", "ai"),
]


def upgrade() -> None:
    op.create_table(
        "content_strings",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("key", sa.String(120), nullable=False),
        sa.Column("description", sa.String(255), nullable=True),
        sa.Column("value_fr", sa.Text(), nullable=False, server_default=sa.text("''")),
        sa.Column("value_en", sa.Text(), nullable=False, server_default=sa.text("''")),
        sa.Column("group", sa.String(60), nullable=False, server_default=sa.text("'general'")),
        sa.Column(
            "updated_by",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint("key", name="uq_content_strings_key"),
    )
    op.create_index("ix_content_strings_key", "content_strings", ["key"], unique=True)
    op.create_index("ix_content_strings_group", "content_strings", ["group"])

    op.create_table(
        "broadcast_notifications",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("target_criteria", JSONB, nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_count", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column(
            "created_by",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index(
        "ix_broadcast_scheduled_at",
        "broadcast_notifications",
        ["scheduled_at"],
    )

    # Seed default content strings
    content_tbl = sa.table(
        "content_strings",
        sa.column("id", UUID(as_uuid=True)),
        sa.column("key", sa.String),
        sa.column("description", sa.String),
        sa.column("value_fr", sa.Text),
        sa.column("value_en", sa.Text),
        sa.column("group", sa.String),
    )
    op.bulk_insert(content_tbl, [
        {
            "id": uuid.uuid4(),
            "key": k,
            "description": desc,
            "value_fr": fr,
            "value_en": en,
            "group": grp,
        }
        for (k, desc, fr, en, grp) in SEED_KEYS
    ])


def downgrade() -> None:
    op.drop_index("ix_broadcast_scheduled_at", table_name="broadcast_notifications")
    op.drop_table("broadcast_notifications")
    op.drop_index("ix_content_strings_group", table_name="content_strings")
    op.drop_index("ix_content_strings_key", table_name="content_strings")
    op.drop_table("content_strings")
