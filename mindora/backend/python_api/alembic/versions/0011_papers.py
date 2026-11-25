"""Create papers table (admin-managed past exams).

Revision ID: 0011_papers
Revises: 0010_notification_dedup
Create Date: 2026-10-17
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0011_papers"
down_revision = "0010_notification_dedup"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "papers",
        sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True),
                  primary_key=True, server_default=sa.text("uuid_generate_v4()")),
        sa.Column("uploader_id", sa.dialects.postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("subject", sa.String(80), nullable=False),
        sa.Column("exam_system", sa.String(40), nullable=False),
        sa.Column("exam_level", sa.String(40), nullable=False),
        sa.Column("exam_year", sa.Integer(), nullable=True),
        sa.Column("language", sa.String(8), nullable=False, server_default="fr"),
        sa.Column("file_data", sa.LargeBinary(), nullable=False),
        sa.Column("file_name", sa.String(255), nullable=False),
        sa.Column("file_size", sa.Integer(), nullable=False),
        sa.Column("mime_type", sa.String(80), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="published"),
        sa.Column("download_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("metadata_json", sa.dialects.postgresql.JSONB(),
                  nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  nullable=False, server_default=sa.text("now()")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_papers_subject", "papers", ["subject"])
    op.create_index("ix_papers_exam_system", "papers", ["exam_system"])
    op.create_index("ix_papers_exam_level", "papers", ["exam_level"])
    op.create_index("ix_papers_exam_year", "papers", ["exam_year"])
    op.create_index("ix_papers_status", "papers", ["status"])
    op.create_index("ix_papers_uploader_id", "papers", ["uploader_id"])


def downgrade() -> None:
    op.drop_table("papers")
