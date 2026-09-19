from pydantic import BaseModel, Field
from datetime import datetime


class ReviewQueueItemOut(BaseModel):
    id: str
    uploader_id: str
    title: str | None
    description: str | None
    category: str | None
    level: str | None
    language: str | None
    status: str
    detected_subject: str | None = None
    detected_level: str | None = None
    detected_language: str | None = None
    quality_score: float | None = None
    duplicate_of_id: str | None = None
    similarity_score: float | None = None
    is_exam: bool = False
    validation_summary: list[str] = []  # human-readable "check: pass/fail (detail)" lines


class RejectDocumentIn(BaseModel):
    reason: str = Field(min_length=3)


class ApproveResultOut(BaseModel):
    document_id: str
    status: str
    credits_awarded: int
    past_paper_created: bool


class AnalyticsOverviewOut(BaseModel):
    total_users: int
    documents_by_status: dict[str, int]


class AuditLogEntryOut(BaseModel):
    id: str
    actor_id: str
    action: str
    target_type: str
    target_id: str
    detail: dict
    created_at: datetime

    class Config:
        from_attributes = True
