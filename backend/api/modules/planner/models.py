from sqlalchemy import String, Date, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column
import uuid
from datetime import date

from api.core.db import Base


class StudyPlan(Base):
    __tablename__ = "study_plans"

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    mode: Mapped[str] = mapped_column(String(20))  # "exam" | "subject"
    target_exam_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    subjects: Mapped[list] = mapped_column(JSON, default=list)
    start_date: Mapped[date] = mapped_column(Date)
    end_date: Mapped[date] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(20), default="active")
