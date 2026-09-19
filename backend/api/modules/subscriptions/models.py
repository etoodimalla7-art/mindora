from datetime import datetime

from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class Subscription(Base):
    __tablename__ = "subscriptions"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    plan_code: Mapped[str] = mapped_column(String(50))
    status: Mapped[str] = mapped_column(String(20), default="active")  # active | canceled | expired
    current_period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    provider_reference: Mapped[str | None] = mapped_column(String(100), nullable=True)
