from sqlalchemy import String, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from api.core.db import Base


class Examination(Base):
    __tablename__ = "examinations"

    country: Mapped[str] = mapped_column(String(100), index=True)
    system: Mapped[str] = mapped_column(String(100), index=True)  # GCE, Baccalauréat, HND, ...
    name: Mapped[str] = mapped_column(String(255))


class PastPaper(Base):
    __tablename__ = "past_papers"

    examination_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("examinations.id"), index=True)
    subject_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("subjects.id"), index=True)
    document_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("documents.id"), nullable=True)
    title: Mapped[str] = mapped_column(String(255))
    level: Mapped[str] = mapped_column(String(100))
    year: Mapped[int] = mapped_column(Integer, index=True)
    session: Mapped[str | None] = mapped_column(String(50), nullable=True)


class PastPaperBookmark(Base):
    __tablename__ = "past_paper_bookmarks"
    __table_args__ = (UniqueConstraint("user_id", "past_paper_id", name="uq_user_past_paper"),)

    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    past_paper_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("past_papers.id"), index=True)
