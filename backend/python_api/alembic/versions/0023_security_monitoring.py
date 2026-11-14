"""add security: login history + alerts

Revision ID: 0023_security_monitoring
Revises: 0022_support_tickets
Create Date: 2026-11-15
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB, UUID


revision = "0023_security_monitoring"
down_revision = "0022_support_tickets"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # admin_login_history
    op.create_table(
        "admin_login_history",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("ip", sa.String(64), nullable=True),
        sa.Column("user_agent", sa.String(500), nullable=True),
        sa.Column("success", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("failure_reason", sa.String(120), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_admin_login_history_user_id", "admin_login_history", ["user_id"])
    op.create_index("ix_admin_login_history_email", "admin_login_history", ["email"])
    op.create_index("ix_admin_login_history_ip", "admin_login_history", ["ip"])
    op.create_index("ix_admin_login_history_success", "admin_login_history", ["success"])
    op.create_index("ix_admin_login_history_created_at", "admin_login_history", ["created_at"])

    # security_alerts
    op.create_table(
        "security_alerts",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("type", sa.String(40), nullable=False),
        sa.Column("severity", sa.String(20), nullable=False, server_default="medium"),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("metadata", JSONB(), nullable=False, server_default=sa.text("'{}'::jsonb")),
        sa.Column("acknowledged", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column(
            "acknowledged_by",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("acknowledged_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_security_alerts_type", "security_alerts", ["type"])
    op.create_index("ix_security_alerts_severity", "security_alerts", ["severity"])
    op.create_index("ix_security_alerts_acknowledged", "security_alerts", ["acknowledged"])
    op.create_index("ix_security_alerts_created_at", "security_alerts", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_security_alerts_created_at", table_name="security_alerts")
    op.drop_index("ix_security_alerts_acknowledged", table_name="security_alerts")
    op.drop_index("ix_security_alerts_severity", table_name="security_alerts")
    op.drop_index("ix_security_alerts_type", table_name="security_alerts")
    op.drop_table("security_alerts")

    op.drop_index("ix_admin_login_history_created_at", table_name="admin_login_history")
    op.drop_index("ix_admin_login_history_success", table_name="admin_login_history")
    op.drop_index("ix_admin_login_history_ip", table_name="admin_login_history")
    op.drop_index("ix_admin_login_history_email", table_name="admin_login_history")
    op.drop_index("ix_admin_login_history_user_id", table_name="admin_login_history")
    op.drop_table("admin_login_history")
