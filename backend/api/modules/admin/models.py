from datetime import datetime

from sqlalchemy import String, JSON, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class AuditLog(Base):
    """Section 56: an append-only record of security-sensitive actions.
    Starts scoped to admin moderation actions (the highest-privilege
    surface that exists so far); other modules can write to this same
    table as their own sensitive actions warrant it, without a schema
    change."""
    __tablename__ = "audit_logs"

    actor_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    action: Mapped[str] = mapped_column(String(100))
    target_type: Mapped[str] = mapped_column(String(50))
    target_id: Mapped[str] = mapped_column(String(100))
    detail: Mapped[dict] = mapped_column(JSON, default=dict)