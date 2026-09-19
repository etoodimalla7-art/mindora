from datetime import datetime
from pydantic import BaseModel


class ProgressOut(BaseModel):
    subject_name: str
    mastery_score: float
    last_studied_at: datetime | None

    class Config:
        from_attributes = True


class ReadinessScoreOut(BaseModel):
    target_exam_name: str
    knowledge: float
    practice: float
    retention: float
    past_papers: float
    weak_topics: float
    consistency: float
    overall: float
    computed_at: datetime

    class Config:
        from_attributes = True


class DashboardOverviewOut(BaseModel):
    streak_days: int
    subjects: list[ProgressOut]
    weakest_subject: str | None
