from sqlalchemy import String, Boolean, ForeignKey, Date
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class User(Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    locale: Mapped[str] = mapped_column(String(5), default="en")
    role: Mapped[str] = mapped_column(String(20), default="student")  # student | contributor | admin
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class EducationProfile(Base):
    __tablename__ = "education_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), unique=True)
    country: Mapped[str] = mapped_column(String(100))
    education_system: Mapped[str] = mapped_column(String(100))  # GCE, Baccalaureat, HND, ...
    level: Mapped[str] = mapped_column(String(100))
    program: Mapped[str | None] = mapped_column(String(255), nullable=True)
    target_exam: Mapped[str | None] = mapped_column(String(255), nullable=True)
    target_exam_date: Mapped[Date | None] = mapped_column(Date, nullable=True)
