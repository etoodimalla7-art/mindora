from datetime import datetime

from sqlalchemy import String, Text, Integer, Boolean, DateTime, JSON, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class NotificationPreference(Base):
    __tablename__ = "notification_preferences"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), unique=True, index=True)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    quiet_hours_start: Mapped[int] = mapped_column(Integer, default=22)  # 24h, e.g. 22 = 10pm
    quiet_hours_end: Mapped[int] = mapped_column(Integer, default=7)    # 24h, e.g. 7 = 7am
    preferred_study_times: Mapped[list] = mapped_column(JSON, default=list)


class Notification(Base):
    __tablename__ = "notifications"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    type: Mapped[str] = mapped_column(String(50))  # session_upcoming | session_missed | exam_countdown
    title: Mapped[str] = mapped_column(String(255))
    body: Mapped[str] = mapped_column(Text)
    # Holds dedupe keys (e.g. {"session_id": "..."}) so the same event
    # never generates a duplicate notification on repeated generation runs.
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    scheduled_for: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
