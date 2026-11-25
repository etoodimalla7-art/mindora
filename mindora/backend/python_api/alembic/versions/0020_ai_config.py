"""add AI config + versions

Revision ID: 0020_ai_config
Revises: 0019_document_archiving
Create Date: 2026-11-14
"""
from __future__ import annotations

import uuid

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


revision = "0020_ai_config"
down_revision = "0019_document_archiving"
branch_labels = None
depends_on = None


DEFAULT_PROMPT = """You are MINDORA, a patient academic tutor for students in Cameroon.
You answer questions clearly, in the same language as the student.
You show your reasoning step by step for math and science.
You never invent citations. If you are not sure about a fact, say so.
You keep answers structured: short intro, main explanation, brief recap.
Never mention that you are an AI language model. Just teach.
If the student provides an image (exercice, page, diagram), read it carefully,
transcribe the visible text before solving, and explain each step."""


def upgrade() -> None:
    op.create_table(
        "ai_configs",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(80), nullable=False),
        sa.Column("system_prompt", sa.Text(), nullable=False),
        sa.Column("model", sa.String(80), nullable=False),
        sa.Column("temperature", sa.Float(), nullable=False),
        sa.Column("max_tokens", sa.Integer(), nullable=False),
        sa.Column("language", sa.String(8), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
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
    )
    op.create_index("ix_ai_configs_is_active", "ai_configs", ["is_active"])

    op.create_table(
        "ai_config_versions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "config_id",
            UUID(as_uuid=True),
            sa.ForeignKey("ai_configs.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("system_prompt", sa.Text(), nullable=False),
        sa.Column("model", sa.String(80), nullable=False),
        sa.Column("temperature", sa.Float(), nullable=False),
        sa.Column("max_tokens", sa.Integer(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "published_by",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "published_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint("config_id", "version", name="uq_ai_config_version"),
    )
    op.create_index(
        "ix_ai_config_versions_config_id", "ai_config_versions", ["config_id"]
    )

    # Seed the initial config from the hardcoded prompt
    configs = sa.table(
        "ai_configs",
        sa.column("id", UUID(as_uuid=True)),
        sa.column("name", sa.String),
        sa.column("system_prompt", sa.Text),
        sa.column("model", sa.String),
        sa.column("temperature", sa.Float),
        sa.column("max_tokens", sa.Integer),
        sa.column("language", sa.String),
        sa.column("is_active", sa.Boolean),
    )
    op.bulk_insert(configs, [
        {
            "id": uuid.uuid4(),
            "name": "default",
            "system_prompt": DEFAULT_PROMPT,
            "model": "gemini-3.1-flash-lite",
            "temperature": 0.5,
            "max_tokens": 1200,
            "language": "fr",
            "is_active": True,
        },
    ])


def downgrade() -> None:
    op.drop_index("ix_ai_config_versions_config_id", table_name="ai_config_versions")
    op.drop_table("ai_config_versions")
    op.drop_index("ix_ai_configs_is_active", table_name="ai_configs")
    op.drop_table("ai_configs")
