"""Create notification_rules table and seed F-13 notification defaults.

Revision ID: 0026_notification_rules
Revises: 0025_flashcards_sm2_stats
Create Date: 2026-11-19
"""
from __future__ import annotations

import uuid

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0026_notification_rules"
down_revision = "0025_flashcards_sm2_stats"
branch_labels = None
depends_on = None

DEFAULT_RULES = [
    ("session_reminder", "session_reminder", 1, "Rappel 15 min avant une session d'étude"),
    ("streak", "streak", 2, "Rappel série quotidienne avant fin de journée"),
    ("exam_countdown", "exam_countdown", 1, "Compte à rebours J-7, J-3, J-1 avant examen"),
    ("inactivity", "inactivity", 3, "Relance douce après 3 jours d'inactivité"),
    ("subscription_expiring", "subscription_expiring", 1, "Alerte expiration abonnement J-7 et J-1"),
]


def upgrade() -> None:
    op.create_table(
        "notification_rules",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("rule_key", sa.String(64), nullable=False, unique=True),
        sa.Column("notif_type", sa.String(40), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("max_per_day", sa.Integer(), nullable=False, server_default="3"),
        sa.Column("quiet_hours_start", sa.Integer(), nullable=False, server_default="22"),
        sa.Column("quiet_hours_end", sa.Integer(), nullable=False, server_default="7"),
        sa.Column("priority", sa.Integer(), nullable=False, server_default="3"),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_notification_rules_rule_key", "notification_rules", ["rule_key"], unique=True)

    conn = op.get_bind()
    for rule_key, notif_type, prio, desc in DEFAULT_RULES:
        conn.execute(
            sa.text(
                """
                INSERT INTO notification_rules (
                    id, rule_key, notif_type, enabled, max_per_day,
                    quiet_hours_start, quiet_hours_end, priority, description
                ) VALUES (
                    :id, :rule_key, :notif_type, true, 3, 22, 7, :priority, :description
                )
                ON CONFLICT (rule_key) DO NOTHING
                """
            ),
            {
                "id": uuid.uuid4(),
                "rule_key": rule_key,
                "notif_type": notif_type,
                "priority": prio,
                "description": desc,
            },
        )


def downgrade() -> None:
    op.drop_index("ix_notification_rules_rule_key", table_name="notification_rules")
    op.drop_table("notification_rules")
