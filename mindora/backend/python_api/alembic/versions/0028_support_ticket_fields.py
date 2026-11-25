"""Add category and closed_at columns to support_tickets.

Revision ID: 0028_support_ticket_fields
Revises: 0027_settings_flags_b3
Create Date: 2026-11-19
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0028_support_ticket_fields"
down_revision = "0027_settings_flags_b3"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "support_tickets",
        sa.Column(
            "category",
            sa.String(50),
            nullable=False,
            server_default="general",
        ),
    )
    op.add_column(
        "support_tickets",
        sa.Column(
            "closed_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column("support_tickets", "closed_at")
    op.drop_column("support_tickets", "category")
