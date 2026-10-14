"""Mock exams, questions, and answers.

Revision ID: 0007_mock_exams
Revises: 0006_document_chunks
Create Date: 2026-02-01
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0007_mock_exams"
down_revision: Union[str, None] = "0006_document_chunks"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "mock_exams",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("subject", sa.String(80), nullable=False),
        sa.Column("academic_level", sa.String(40), nullable=True),
        sa.Column("question_count", sa.Integer, nullable=False),
        sa.Column("duration_minutes", sa.Integer, nullable=False),
        sa.Column(
            "difficulty", sa.String(20), nullable=False, server_default="medium"
        ),
        sa.Column(
            "source_document_ids",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column(
            "status", sa.String(20), nullable=False, server_default="draft"
        ),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("graded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("score", sa.Float, nullable=True),
        sa.Column("correct_count", sa.Integer, nullable=True),
        sa.Column("wrong_count", sa.Integer, nullable=True),
        sa.Column("skipped_count", sa.Integer, nullable=True),
        sa.Column("feedback_summary", sa.Text, nullable=True),
        sa.Column(
            "metadata_json",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_mock_exams_user_id", "mock_exams", ["user_id"])
    op.create_index("ix_mock_exams_status", "mock_exams", ["status"])

    op.create_table(
        "mock_questions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "exam_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("mock_exams.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("position", sa.Integer, nullable=False),
        sa.Column("question_type", sa.String(20), nullable=False),
        sa.Column("prompt", sa.Text, nullable=False),
        sa.Column(
            "options",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column("correct_answer", sa.Text, nullable=False),
        sa.Column("explanation", sa.Text, nullable=True),
        sa.Column(
            "difficulty", sa.String(20), nullable=False, server_default="medium"
        ),
        sa.Column("points", sa.Integer, nullable=False, server_default="1"),
        sa.Column(
            "metadata_json",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_mock_questions_exam_id", "mock_questions", ["exam_id"])

    op.create_table(
        "mock_answers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "exam_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("mock_exams.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "question_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("mock_questions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("user_answer", sa.Text, nullable=True),
        sa.Column("is_correct", sa.Boolean, nullable=True),
        sa.Column("points_awarded", sa.Integer, nullable=False, server_default="0"),
        sa.Column("time_spent_seconds", sa.Integer, nullable=True),
        sa.Column("ai_feedback", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint(
            "exam_id", "question_id", name="uq_mock_answers_exam_question"
        ),
    )
    op.create_index("ix_mock_answers_exam_id", "mock_answers", ["exam_id"])
    op.create_index("ix_mock_answers_question_id", "mock_answers", ["question_id"])


def downgrade() -> None:
    op.drop_index("ix_mock_answers_question_id", table_name="mock_answers")
    op.drop_index("ix_mock_answers_exam_id", table_name="mock_answers")
    op.drop_table("mock_answers")
    op.drop_index("ix_mock_questions_exam_id", table_name="mock_questions")
    op.drop_table("mock_questions")
    op.drop_index("ix_mock_exams_status", table_name="mock_exams")
    op.drop_index("ix_mock_exams_user_id", table_name="mock_exams")
    op.drop_table("mock_exams")
