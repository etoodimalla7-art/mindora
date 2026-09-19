from sqlalchemy import String, ForeignKey, JSON, Integer
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class Subject(Base):
    __tablename__ = "subjects"

    name: Mapped[str] = mapped_column(String(255), index=True)
    education_system: Mapped[str] = mapped_column(String(100))
    level: Mapped[str] = mapped_column(String(100))


class Course(Base):
    __tablename__ = "courses"

    subject_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("subjects.id"), index=True)
    owner_user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    title: Mapped[str] = mapped_column(String(255))
    outline: Mapped[dict] = mapped_column(JSON, default=dict)


class Topic(Base):
    __tablename__ = "topics"

    course_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("courses.id"), index=True)
    title: Mapped[str] = mapped_column(String(255))
    order_index: Mapped[int] = mapped_column(Integer, default=0)
