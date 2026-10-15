"""Notification and device models."""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin

# ---------------------------------------------------------------------------
# Notification types (aligned with rules/templates)
# ---------------------------------------------------------------------------
NOTIF_TYPE_SESSION_REMINDER = "session_reminder"
NOTIF_TYPE_EXAM_COUNTDOWN = "exam_countdown"
NOTIF_TYPE_STREAK = "streak"
NOTIF_TYPE_MILESTONE = "milestone"
NOTIF_TYPE_INACTIVITY = "inactivity"
NOTIF_TYPE_WEAK_TOPIC = "weak_topic"
NOTIF_TYPE_SYSTEM = "system"
NOTIF_TYPE_SUBSCRIPTION_EXPIRING = "subscription_expiring"
NOTIF_TYPE_DOCUMENT_READY = "document_ready"
NOTIF_TYPE_SESSION_COMPLETED = "session_completed"

# Delivery status
NOTIF_STATUS_PENDING = "pending"
NOTIF_STATUS_SENT = "sent"
NOTIF_STATUS_FAILED = "failed"
NOTIF_STATUS_READ = "read"
NOTIF_STATUS_NO_DEVICE = "no_device"
NOTIF_STATUS_SKIPPED_DUPLICATE = "skipped_duplicate"
NOTIF_STATUS_SKIPPED_PREF = "skipped_pref"
NOTIF_STATUS_SKIPPED_QUIET_HOURS = "skipped_quiet_hours"
NOTIF_STATUS_SKIPPED_DAILY_LIMIT = "skipped_daily_limit"


class Device(Base, UUIDMixin, TimestampMixin):
    """A user device registered for push notifications."""

    __tablename__ = "devices"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    fcm_token: Mapped[str] = mapped_column(
        String(500), unique=True, index=True, nullable=False
    )

    platform: Mapped[str] = mapped_column(String(20), default="android", nullable=False)

    device_model: Mapped[str | None] = mapped_column(String(120), nullable=True)
    os_version: Mapped[str | None] = mapped_column(String(40), nullable=True)
    app_version: Mapped[str | None] = mapped_column(String(40), nullable=True)

    notifications_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )

    last_seen_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)


class Notification(Base, UUIDMixin, TimestampMixin):
    """A notification sent (or scheduled) to a user."""

    __tablename__ = "notifications"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    type: Mapped[str] = mapped_column(String(40), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)

    deep_link: Mapped[str | None] = mapped_column(String(500), nullable=True)

    reference_type: Mapped[str | None] = mapped_column(String(40), nullable=True)
    reference_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True)

    status: Mapped[str] = mapped_column(
        String(30), default=NOTIF_STATUS_PENDING, nullable=False, index=True
    )
    sent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    read_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    fcm_message_id: Mapped[str | None] = mapped_column(String(200), nullable=True)

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    # ---------------------------------------------------------------------
    # 12B.3 additions — dedup + priority + template tracking
    # ---------------------------------------------------------------------
    dedup_key: Mapped[str | None] = mapped_column(
        String(200), nullable=True, index=True
    )
    priority: Mapped[int] = mapped_column(Integer, default=3, nullable=False)
    template_key: Mapped[str | None] = mapped_column(String(40), nullable=True)

    __table_args__ = (
        Index(
            "ix_notifications_user_dedup_unique",
            "user_id",
            "dedup_key",
            unique=True,
            postgresql_where=text("dedup_key IS NOT NULL"),
        ),
    )


class NotificationPreference(Base, UUIDMixin, TimestampMixin):
    """User's global notification preferences."""

    __tablename__ = "notification_preferences"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )

    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    session_reminders: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    exam_countdown: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    streak_reminders: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    milestones: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    inactivity_nudges: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    weak_topic_alerts: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    max_per_day: Mapped[int] = mapped_column(Integer, default=3, nullable=False)

    quiet_hours_start: Mapped[int] = mapped_column(Integer, default=22, nullable=False)
    quiet_hours_end: Mapped[int] = mapped_column(Integer, default=7, nullable=False)

    reminder_minutes_before: Mapped[int] = mapped_column(Integer, default=15, nullable=False)

    timezone: Mapped[str] = mapped_column(
        String(64), default="Africa/Douala", nullable=False
    )
