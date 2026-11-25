"""Add SM-2 review telemetry fields and due lookup index on flashcards.

Revision ID: 0025_flashcards_sm2_stats
Revises: 0024_app_settings
Create Date: 2026-11-19
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0025_flashcards_sm2_stats"
down_revision = "0024_app_settings"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "flashcards",
        sa.Column("last_quality", sa.Integer(), nullable=True),
    )
    op.add_column(
        "flashcards",
        sa.Column("review_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_index(
        "ix_flashcards_deck_due",
        "flashcards",
        ["deck_id", "next_review_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_flashcards_deck_due", table_name="flashcards")
    op.drop_column("flashcards", "review_count")
    op.drop_column("flashcards", "last_quality")
