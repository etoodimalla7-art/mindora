from datetime import datetime

from sqlalchemy import String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class CreditAccount(Base):
    __tablename__ = "credit_accounts"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), unique=True, index=True)
    balance: Mapped[int] = mapped_column(Integer, default=0)


class CreditTransaction(Base):
    __tablename__ = "credit_transactions"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    delta: Mapped[int] = mapped_column(Integer)  # positive = grant, negative = spend
    reason: Mapped[str] = mapped_column(String(100))
    ref_id: Mapped[str | None] = mapped_column(String(100), nullable=True)


class Download(Base):
    """Generalized over resource_type so it can cover past papers now
    and documents/other resources later without a schema change."""
    __tablename__ = "downloads"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    resource_type: Mapped[str] = mapped_column(String(50))  # "past_paper" | "document"
    resource_id: Mapped[str] = mapped_column(String(100))
    downloaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
