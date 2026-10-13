"""Credit ledger and download history."""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import BigInteger, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin

# Ledger reasons.
CREDIT_REASON_SIGNUP = "signup_bonus"
CREDIT_REASON_CONTRIBUTION = "contribution_approved"
CREDIT_REASON_DOWNLOAD = "download"
CREDIT_REASON_SUBSCRIPTION = "subscription_grant"
CREDIT_REASON_ADMIN = "admin_adjustment"
CREDIT_REASON_REFUND = "refund"


class CreditLedger(Base, UUIDMixin, TimestampMixin):
    """Immutable ledger of credit changes. Balance is derived by summing."""

    __tablename__ = "credit_ledger"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )

    # Positive = credit granted, negative = credit consumed.
    delta: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str] = mapped_column(String(40), nullable=False, index=True)

    # Optional reference to the triggering document/contribution/subscription.
    reference_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True)
    reference_type: Mapped[str | None] = mapped_column(String(40), nullable=True)

    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)


class Download(Base, UUIDMixin, TimestampMixin):
    """A user-initiated download of an approved document."""

    __tablename__ = "downloads"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    document_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("documents.id", ondelete="CASCADE"), index=True, nullable=False
    )

    # Credits spent on this download (0 for the free tier).
    credits_spent: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    downloaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    ip_address: Mapped[str | None] = mapped_column(String(64), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(String(255), nullable=True)

    size_bytes: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
