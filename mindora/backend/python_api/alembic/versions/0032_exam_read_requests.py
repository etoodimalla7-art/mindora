"""Create exam_read_requests table for justified admin access to student exams.

Revision ID: 0032_exam_read_requests
Revises: 0031_admin_curriculum_content
Create Date: 2026-11-19
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0032_exam_read_requests"
down_revision = "0031_admin_curriculum_content"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "exam_read_requests",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "admin_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "student_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("ticket_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index(
        "ix_exam_read_requests_admin_student",
        "exam_read_requests",
        ["admin_id", "student_id", "expires_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_exam_read_requests_admin_student", table_name="exam_read_requests")
    op.drop_table("exam_read_requests")
