"""add study groups (phase 13)

Revision ID: 0014_study_groups
Revises: 0013_flashcards
Create Date: 2026-11-11
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

# revision identifiers, used by Alembic.
revision = "0014_study_groups"
down_revision = "0013_flashcards"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # --- study_groups ---
    op.create_table(
        "study_groups",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("exam_system", sa.String(40), nullable=True),
        sa.Column("exam_level", sa.String(40), nullable=True),
        sa.Column("subject", sa.String(80), nullable=True),
        sa.Column(
            "creator_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("is_private", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("member_count", sa.Integer(), nullable=False, server_default=sa.text("1")),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.create_index("ix_study_groups_name", "study_groups", ["name"])
    op.create_index("ix_study_groups_creator_id", "study_groups", ["creator_id"])

    # --- study_group_members ---
    op.create_table(
        "study_group_members",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "group_id",
            UUID(as_uuid=True),
            sa.ForeignKey("study_groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "joined_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.UniqueConstraint(
            "group_id", "user_id", name="uq_study_group_members_group_user"
        ),
    )
    op.create_index(
        "ix_study_group_members_group_id", "study_group_members", ["group_id"]
    )
    op.create_index(
        "ix_study_group_members_user_id", "study_group_members", ["user_id"]
    )

    # --- group_messages ---
    op.create_table(
        "group_messages",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "group_id",
            UUID(as_uuid=True),
            sa.ForeignKey("study_groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
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
    )
    op.create_index("ix_group_messages_group_id", "group_messages", ["group_id"])
    op.create_index("ix_group_messages_created_at", "group_messages", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_group_messages_created_at", table_name="group_messages")
    op.drop_index("ix_group_messages_group_id", table_name="group_messages")
    op.drop_table("group_messages")

    op.drop_index(
        "ix_study_group_members_user_id", table_name="study_group_members"
    )
    op.drop_index(
        "ix_study_group_members_group_id", table_name="study_group_members"
    )
    op.drop_table("study_group_members")

    op.drop_index("ix_study_groups_creator_id", table_name="study_groups")
    op.drop_index("ix_study_groups_name", table_name="study_groups")
    op.drop_table("study_groups")
