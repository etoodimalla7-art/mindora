from datetime import datetime
from pydantic import BaseModel


class StudySessionOut(BaseModel):
    id: str
    subject_name: str
    topic_title: str
    scheduled_at: datetime
    duration_minutes: int
    status: str

    class Config:
        from_attributes = True
