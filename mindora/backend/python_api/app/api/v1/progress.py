"""Student progress & mastery overview endpoints."""
from __future__ import annotations

import uuid
from datetime import date, datetime

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select

from app.api.deps import CurrentUserId, SessionDep
from app.models.mock_exam import MOCK_STATUS_GRADED, MockExam
from app.models.plan import StudySession
from app.models.progress import TopicProgress
from app.schemas.dashboard import ReadinessBreakdown, WeakTopic
from app.services.dashboard_service import DashboardService
from app.services.progress_service import ProgressService

router = APIRouter()


class TopicMasteryOut(BaseModel):
    subject: str
    topic: str
    mastery: float
    confidence: float
    questions_seen: int
    questions_correct: int
    minutes_studied: int
    last_reviewed_at: datetime | None = None

    class Config:
        from_attributes = True


class ProgressOverviewOut(BaseModel):
    streak_days: int
    readiness_score: int
    readiness_breakdown: ReadinessBreakdown
    total_minutes_studied: int
    sessions_completed: int
    mock_exams_completed: int
    average_exam_score: float | None = None
    weak_topics: list[WeakTopic] = Field(default_factory=list)
    topics: list[TopicMasteryOut] = Field(default_factory=list)


class UserProgressMeOut(BaseModel):
    user_id: uuid.UUID
    current_streak: int
    longest_streak: int
    total_xp: int
    total_minutes: int
    sessions_completed: int
    flashcards_reviewed: int
    exams_completed: int
    last_activity_date: date | None = None
    readiness_score: int
    readiness_breakdown: ReadinessBreakdown
    weak_topics: list[WeakTopic] = Field(default_factory=list)
    topics: list[TopicMasteryOut] = Field(default_factory=list)


class HeatmapDayOut(BaseModel):
    date: str
    minutes: int
    sessions: int
    flashcards: int
    exams: int
    activity_level: int


class ProgressHistoryOut(BaseModel):
    days: int
    current_streak: int
    longest_streak: int
    active_days: int
    heatmap: list[HeatmapDayOut]


class ProgressRecommendationOut(BaseModel):
    action_type: str
    subject: str
    topic: str
    title: str
    reason: str
    estimated_minutes: int
    deep_link: str


@router.get("/overview", response_model=ProgressOverviewOut)
async def progress_overview(
    session: SessionDep, user_id: CurrentUserId
) -> ProgressOverviewOut:
    """Return full student progress, topic mastery, and readiness analytics."""
    dash = await DashboardService(session).build(user_id)

    topics_rows = (
        await session.execute(
            select(TopicProgress)
            .where(TopicProgress.user_id == user_id)
            .order_by(TopicProgress.mastery.asc(), TopicProgress.updated_at.desc())
        )
    ).scalars().all()

    sessions_stats = (
        await session.execute(
            select(
                func.count(StudySession.id),
                func.coalesce(func.sum(StudySession.duration_minutes), 0),
            ).where(
                StudySession.user_id == user_id,
                StudySession.status == "completed",
            )
        )
    ).one()

    exams_stats = (
        await session.execute(
            select(
                func.count(MockExam.id),
                func.avg(MockExam.score),
            ).where(
                MockExam.user_id == user_id,
                MockExam.status == MOCK_STATUS_GRADED,
            )
        )
    ).one()

    topic_minutes = sum(t.minutes_studied for t in topics_rows)
    total_minutes = max(int(sessions_stats[1] or 0), topic_minutes)
    avg_score = round(float(exams_stats[1]), 1) if exams_stats[1] is not None else None

    return ProgressOverviewOut(
        streak_days=dash.streak_days,
        readiness_score=dash.readiness_score,
        readiness_breakdown=dash.readiness_breakdown,
        total_minutes_studied=total_minutes,
        sessions_completed=int(sessions_stats[0] or 0),
        mock_exams_completed=int(exams_stats[0] or 0),
        average_exam_score=avg_score,
        weak_topics=dash.weak_topics,
        topics=[TopicMasteryOut.model_validate(t) for t in topics_rows],
    )


@router.get("/me", response_model=UserProgressMeOut)
async def progress_me(
    session: SessionDep, user_id: CurrentUserId
) -> UserProgressMeOut:
    """Return server-computed streak, XP, study volume, and topic mastery."""
    data = await ProgressService(session).get_my_progress(user_id)
    return UserProgressMeOut(
        **{
            **data,
            "topics": [TopicMasteryOut.model_validate(t) for t in data["topics"]],
        }
    )


@router.get("/history", response_model=ProgressHistoryOut)
async def progress_history(
    session: SessionDep,
    user_id: CurrentUserId,
    days: int = Query(default=30, ge=1, le=90),
) -> ProgressHistoryOut:
    """Return daily activity heatmap over 30 or 90 days."""
    data = await ProgressService(session).get_history(user_id, days=days)
    return ProgressHistoryOut(**data)


@router.get("/recommendation", response_model=ProgressRecommendationOut)
async def progress_recommendation(
    session: SessionDep, user_id: CurrentUserId
) -> ProgressRecommendationOut:
    """Return personalized next-best study action."""
    data = await ProgressService(session).get_recommendation(user_id)
    return ProgressRecommendationOut(**data)
