"""Conversation and message models for the AI tutor."""
from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    pass


class Conversation(Base, UUIDMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "conversations"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    title: Mapped[str] = mapped_column(String(200), default="New conversation", nullable=False)

    # Optional context binding (subject, exam, plan).
    subject: Mapped[str | None] = mapped_column(String(80), nullable=True)
    context_type: Mapped[str | None] = mapped_column(String(40), nullable=True)
    context_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True)

    is_archived: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    message_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    messages: Mapped[list["Message"]] = relationship(
        back_populates="conversation",
        cascade="all, delete-orphan",
        order_by="Message.created_at",
        lazy="selectin",
    )


class Message(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "messages"

    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), index=True, nullable=False
    )

    # user | assistant | system | tool
    role: Mapped[str] = mapped_column(String(16), nullable=False)

    content: Mapped[str] = mapped_column(Text, nullable=False)

    # Token / cost tracking.
    prompt_tokens: Mapped[int | None] = mapped_column(Integer, nullable=True)
    completion_tokens: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Which tools were invoked for this message.
    tools_used: Mapped[list] = mapped_column(JSONB, default=list, nullable=False)

    # Model identifier (e.g. gemini-1.5-flash).
    model: Mapped[str | None] = mapped_column(String(80), nullable=True)
    provider: Mapped[str | None] = mapped_column(String(40), nullable=True)

    # Free-form extras: latency_ms, finish_reason, error, etc.
    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    conversation: Mapped[Conversation] = relationship(back_populates="messages")
