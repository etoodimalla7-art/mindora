from datetime import date
from pydantic import BaseModel, Field


class CreateExamPlanIn(BaseModel):
    target_exam_name: str = Field(min_length=1)
    subject_names: list[str] = Field(min_length=1)
    exam_date: date
    minutes_per_session: int = Field(default=45, ge=15, le=240)


class CreateSubjectPlanIn(BaseModel):
    subject_name: str = Field(min_length=1)
    topic_title: str | None = None
    duration_days: int = Field(gt=0, le=180)
    minutes_per_session: int = Field(default=45, ge=15, le=240)


class StudyPlanOut(BaseModel):
    id: str
    mode: str
    target_exam_name: str | None
    subjects: list[str]
    start_date: date
    end_date: date
    status: str
    session_count: int


class RescheduleOut(BaseModel):
    rescheduled_count: int
