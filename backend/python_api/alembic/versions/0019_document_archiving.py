"""add archiving fields to documents

Revision ID: 0019_document_archiving
Revises: 0018_user_suspension
Create Date: 2026-11-14
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


revision = "0019_document_archiving"
down_revision = "0018_user_suspension"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "documents",
        sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "documents",
        sa.Column(
            "archived_by",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
    )
    op.create_index("ix_documents_archived_at", "documents", ["archived_at"])


def downgrade() -> None:
    op.drop_index("ix_documents_archived_at", table_name="documents")
    op.drop_column("documents", "archived_by")
    op.drop_column("documents", "archived_at")
