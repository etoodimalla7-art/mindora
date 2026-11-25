"""add direct messages (phase 13.7)

Revision ID: 0015_direct_messages
Revises: 0014_study_groups
Create Date: 2026-11-11
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


revision = "0015_direct_messages"
down_revision = "0014_study_groups"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # --- direct_conversations ---
    op.create_table(
        "direct_conversations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_a_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_b_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column("last_message_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("user_a_id", "user_b_id", name="uq_direct_conv_pair"),
    )
    op.create_index(
        "ix_direct_conversations_user_a_id",
        "direct_conversations",
        ["user_a_id"],
    )
    op.create_index(
        "ix_direct_conversations_user_b_id",
        "direct_conversations",
        ["user_b_id"],
    )

    # --- direct_messages ---
    op.create_table(
        "direct_messages",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "conversation_id",
            UUID(as_uuid=True),
            sa.ForeignKey("direct_conversations.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "sender_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_direct_messages_conversation_id",
        "direct_messages",
        ["conversation_id"],
    )
    op.create_index(
        "ix_direct_messages_created_at",
        "direct_messages",
        ["created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_direct_messages_created_at", table_name="direct_messages")
    op.drop_index("ix_direct_messages_conversation_id", table_name="direct_messages")
    op.drop_table("direct_messages")

    op.drop_index(
        "ix_direct_conversations_user_b_id", table_name="direct_conversations"
    )
    op.drop_index(
        "ix_direct_conversations_user_a_id", table_name="direct_conversations"
    )
    op.drop_table("direct_conversations")
