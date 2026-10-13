"""Documents, analyses, duplicates, description validations, credits, downloads.

Revision ID: 0004_documents_and_credits
Revises: 0003_topic_progress
Create Date: 2026-01-03
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0004_documents_and_credits"
down_revision: Union[str, None] = "0003_topic_progress"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ---------- documents ----------
    op.create_table(
        "documents",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "owner_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("category", sa.String(80), nullable=True),
        sa.Column("academic_level", sa.String(40), nullable=True),
        sa.Column("language", sa.String(8), nullable=False, server_default="en"),
        sa.Column("is_exam_related", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("exam_system", sa.String(40), nullable=True),
        sa.Column("exam_name", sa.String(120), nullable=True),
        sa.Column("exam_year", sa.Integer, nullable=True),
        sa.Column("exam_session", sa.String(40), nullable=True),
        sa.Column("document_type", sa.String(60), nullable=True),
        sa.Column("content", sa.LargeBinary, nullable=True),
        sa.Column("original_filename", sa.String(255), nullable=False),
        sa.Column("mime_type", sa.String(120), nullable=False),
        sa.Column("size_bytes", sa.BigInteger, nullable=False, server_default="0"),
        sa.Column("page_count", sa.Integer, nullable=True),
        sa.Column("content_hash", sa.String(64), nullable=True),
        sa.Column("text_hash", sa.String(64), nullable=True),
        sa.Column("extracted_text", sa.Text, nullable=True),
        sa.Column("status", sa.String(24), nullable=False, server_default="draft"),
        sa.Column("rejection_reason", sa.Text, nullable=True),
        sa.Column("moderation_notes", sa.Text, nullable=True),
        sa.Column("download_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("quality_score", sa.Float, nullable=False, server_default="0"),
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
    op.create_index("ix_documents_owner_id", "documents", ["owner_id"])
    op.create_index("ix_documents_status", "documents", ["status"])
    op.create_index("ix_documents_content_hash", "documents", ["content_hash"])
    op.create_index("ix_documents_text_hash", "documents", ["text_hash"])

    # ---------- document_analyses ----------
    op.create_table(
        "document_analyses",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "document_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("documents.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("detected_language", sa.String(8), nullable=True),
        sa.Column("language_confidence", sa.Float, nullable=False, server_default="0"),
        sa.Column("detected_subject", sa.String(80), nullable=True),
        sa.Column("subject_confidence", sa.Float, nullable=False, server_default="0"),
        sa.Column("detected_level", sa.String(40), nullable=True),
        sa.Column("level_confidence", sa.Float, nullable=False, server_default="0"),
        sa.Column("detected_doc_type", sa.String(60), nullable=True),
        sa.Column("doc_type_confidence", sa.Float, nullable=False, server_default="0"),
        sa.Column("is_spam", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("is_inappropriate", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("contains_pii", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("quality_score", sa.Float, nullable=False, server_default="0"),
        sa.Column(
            "keywords",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column("summary", sa.Text, nullable=True),
        sa.Column(
            "raw_response",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_document_analyses_document_id", "document_analyses", ["document_id"])

    # ---------- document_duplicates ----------
    op.create_table(
        "document_duplicates",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "document_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("documents.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "candidate_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("documents.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("similarity", sa.Float, nullable=False, server_default="0"),
        sa.Column("matched_on", sa.String(24), nullable=False, server_default="hash"),
        sa.Column("reviewed", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("verdict", sa.String(24), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_document_duplicates_document_id", "document_duplicates", ["document_id"])
    op.create_index("ix_document_duplicates_candidate_id", "document_duplicates", ["candidate_id"])

    # ---------- description_validations ----------
    op.create_table(
        "description_validations",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "document_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("documents.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("word_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("unique_word_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("repetition_ratio", sa.Float, nullable=False, server_default="0"),
        sa.Column("passed", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("failure_reason", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index(
        "ix_description_validations_document_id",
        "description_validations",
        ["document_id"],
    )

    # ---------- credit_ledger ----------
    op.create_table(
        "credit_ledger",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("delta", sa.Integer, nullable=False),
        sa.Column("reason", sa.String(40), nullable=False),
        sa.Column("reference_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("reference_type", sa.String(40), nullable=True),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column(
            "metadata_json",
            postgresql.JSONB,
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_credit_ledger_user_id", "credit_ledger", ["user_id"])
    op.create_index("ix_credit_ledger_reason", "credit_ledger", ["reason"])

    # ---------- downloads ----------
    op.create_table(
        "downloads",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "document_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("documents.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("credits_spent", sa.Integer, nullable=False, server_default="0"),
        sa.Column("downloaded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ip_address", sa.String(64), nullable=True),
        sa.Column("user_agent", sa.String(255), nullable=True),
        sa.Column("size_bytes", sa.BigInteger, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_downloads_user_id", "downloads", ["user_id"])
    op.create_index("ix_downloads_document_id", "downloads", ["document_id"])


def downgrade() -> None:
    op.drop_index("ix_downloads_document_id", table_name="downloads")
    op.drop_index("ix_downloads_user_id", table_name="downloads")
    op.drop_table("downloads")

    op.drop_index("ix_credit_ledger_reason", table_name="credit_ledger")
    op.drop_index("ix_credit_ledger_user_id", table_name="credit_ledger")
    op.drop_table("credit_ledger")

    op.drop_index(
        "ix_description_validations_document_id", table_name="description_validations"
    )
    op.drop_table("description_validations")

    op.drop_index(
        "ix_document_duplicates_candidate_id", table_name="document_duplicates"
    )
    op.drop_index(
        "ix_document_duplicates_document_id", table_name="document_duplicates"
    )
    op.drop_table("document_duplicates")

    op.drop_index(
        "ix_document_analyses_document_id", table_name="document_analyses"
    )
    op.drop_table("document_analyses")

    op.drop_index("ix_documents_text_hash", table_name="documents")
    op.drop_index("ix_documents_content_hash", table_name="documents")
    op.drop_index("ix_documents_status", table_name="documents")
    op.drop_index("ix_documents_owner_id", table_name="documents")
    op.drop_table("documents")
