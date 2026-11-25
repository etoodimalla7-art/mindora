"""add app settings + feature flags + seed

Revision ID: 0024_app_settings
Revises: 0023_security_monitoring
Create Date: 2026-11-15
"""
from __future__ import annotations

import json

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB, UUID


revision = "0024_app_settings"
down_revision = "0023_security_monitoring"
branch_labels = None
depends_on = None


# ---------- Seed data ----------

SEED_SETTINGS = [
    # (key, value, description)
    ("app.name", "MINDORA", "Nom de l'application"),
    (
        "app.tagline",
        {
            "fr": "Ton tuteur académique IA",
            "en": "Your AI academic tutor",
        },
        "Tagline bilingue",
    ),
    ("app.logo_url", "", "URL du logo (vide = logo par défaut)"),
    ("app.primary_color", "#6E8DFF", "Couleur primaire (hex)"),
    ("app.default_language", "fr", "Langue par défaut (fr|en)"),
    ("app.active_languages", ["fr", "en"], "Langues actives"),
    (
        "education_systems",
        [
            "GCE_O_LEVEL",
            "GCE_A_LEVEL",
            "BEPC",
            "PROBATOIRE",
            "BAC",
            "HND",
            "BTS",
            "LICENCE",
            "MASTER",
        ],
        "Systèmes éducatifs supportés",
    ),
    (
        "subjects",
        [
            "Mathematics",
            "Physics",
            "Chemistry",
            "Biology",
            "French",
            "English",
            "History",
            "Geography",
            "Philosophy",
            "Economics",
        ],
        "Matières disponibles",
    ),
    (
        "levels",
        [
            "Form 1",
            "Form 2",
            "Form 3",
            "Form 4",
            "Form 5",
            "Lower Six",
            "Upper Six",
            "Terminale",
            "Première",
            "Seconde",
        ],
        "Niveaux académiques",
    ),
    ("years", [2020, 2021, 2022, 2023, 2024, 2025, 2026], "Années disponibles"),
    (
        "maintenance",
        {"enabled": False, "message": "", "eta": None},
        "Mode maintenance",
    ),
]

SEED_FLAGS = [
    ("ai_chat", True, "Chat IA avec RAG"),
    ("voice_input", True, "Saisie vocale (STT)"),
    ("vision", True, "Analyse d'images par IA"),
    ("tts", True, "Lecture texte-parole"),
    ("mock_exams", True, "Examens blancs"),
    ("flashcards", True, "Flashcards SM-2"),
    ("study_groups", True, "Groupes d'étude"),
    ("direct_messages", True, "Messages directs 1-to-1"),
]


def upgrade() -> None:
    # --- app_settings ---
    op.create_table(
        "app_settings",
        sa.Column("key", sa.String(80), primary_key=True),
        sa.Column("value", JSONB(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column(
            "updated_by",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    # Seed
    for key, value, description in SEED_SETTINGS:
        op.execute(
            sa.text(
                """
                INSERT INTO app_settings (key, value, description)
                VALUES (:key, CAST(:value AS jsonb), :description)
                ON CONFLICT (key) DO NOTHING
                """
            ).bindparams(
                key=key,
                value=json.dumps(value, ensure_ascii=False),
                description=description,
            )
        )

    # --- feature_flags ---
    op.create_table(
        "feature_flags",
        sa.Column("key", sa.String(80), primary_key=True),
        sa.Column("enabled", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column(
            "updated_by",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    for key, enabled, desc in SEED_FLAGS:
        op.execute(
            sa.text(
                """
                INSERT INTO feature_flags (key, enabled, description)
                VALUES (:key, :enabled, :description)
                ON CONFLICT (key) DO NOTHING
                """
            ).bindparams(key=key, enabled=enabled, description=desc)
        )


def downgrade() -> None:
    op.drop_table("feature_flags")
    op.drop_table("app_settings")
