"""Mock exam schemas."""
from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class CreateMockExamRequest(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    subject: str = Field(min_length=1, max_length=80)
    academic_level: str | None = Field(default=None, max_length=40)
    question_count: int = Field(default=10, ge=3, le=50)
    duration_minutes: int = Field(default=30, ge=5, le=240)
    difficulty: str = Field(default="medium", pattern="^(easy|medium|hard|mixed)$")
    source_document_ids: list[uuid.UUID] = Field(default_factory=list)


class OptionOut(BaseModel):
    label: str
    text: str


class MockQuestionOut(BaseModel):
    id: uuid.UUID
    position: int
    question_type: str
    prompt: str
    options: list[dict] = Field(default_factory=list)
    difficulty: str
    points: int
    # correct_answer is NOT returned while the exam is in progress.

    class Config:
        from_attributes = True


class MockQuestionRevealed(MockQuestionOut):
    correct_answer: str
    explanation: str | None = None


class MockExamOut(BaseModel):
    id: uuid.UUID
    title: str
    subject: str
    academic_level: str | None = None
    question_count: int
    duration_minutes: int
    difficulty: str
    status: str
    started_at: datetime | None = None
    submitted_at: datetime | None = None
    graded_at: datetime | None = None
    score: float | None = None
    correct_count: int | None = None
    wrong_count: int | None = None
    skipped_count: int | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class MockExamDetail(MockExamOut):
    questions: list[MockQuestionOut] = Field(default_factory=list)


class SubmitAnswerRequest(BaseModel):
    question_id: uuid.UUID
    answer: str = Field(max_length=2000)
    time_spent_seconds: int | None = Field(default=None, ge=0)


class SubmitAllRequest(BaseModel):
    """Batch submission: send every answer at once when the timer ends."""

    answers: list[SubmitAnswerRequest] = Field(default_factory=list)


class AnswerResult(BaseModel):
    question_id: uuid.UUID
    user_answer: str | None
    is_correct: bool | None
    points_awarded: int
    correct_answer: str
    explanation: str | None = None
    ai_feedback: str | None = None


class MockExamResults(MockExamOut):
    answers: list[AnswerResult] = Field(default_factory=list)
    feedback_summary: str | None = None
    # Breakdown by topic (from question metadata)
    topic_breakdown: dict[str, dict[str, int]] = Field(default_factory=dict)
