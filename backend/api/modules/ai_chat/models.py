from sqlalchemy import String, ForeignKey, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class Conversation(Base):
    __tablename__ = "conversations"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    title: Mapped[str | None] = mapped_column(String(255), nullable=True)
    # Section 59's preference memory, scoped per-conversation: depth,
    # socratic mode, etc. Merged (not replaced) on every message by
    # tutor_style.merge_style_preferences.
    style_preferences: Mapped[dict] = mapped_column(JSON, default=dict)


class Message(Base):
    __tablename__ = "messages"

    conversation_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("conversations.id"), index=True)
    role: Mapped[str] = mapped_column(String(20))  # "user" | "assistant"
    content: Mapped[str] = mapped_column(Text)
    # Records intent/tools_used/source_document_id per assistant message —
    # this is what section 76's "never pretend to know something it
    # doesn't" is auditable against.
    tool_trace: Mapped[dict] = mapped_column(JSON, default=dict)
