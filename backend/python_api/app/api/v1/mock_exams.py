"""Mock exam REST endpoints."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, status

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.mock_exam import (
    CreateMockExamRequest,
    MockExamDetail,
    MockExamOut,
    MockExamResults,
    SubmitAnswerRequest,
)
from app.services.mock_exam_service import MockExamService

router = APIRouter()


@router.post(
    "",
    response_model=MockExamDetail,
    status_code=status.HTTP_201_CREATED,
)
async def create_exam(
    payload: CreateMockExamRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> MockExamDetail:
    """Generate a new mock exam with AI-produced questions."""
    return await MockExamService(session).create(user_id, payload)


@router.get("", response_model=list[MockExamOut])
async def list_exams(
    session: SessionDep, user_id: CurrentUserId
) -> list[MockExamOut]:
    return await MockExamService(session).list_exams(user_id)


@router.get("/{exam_id}", response_model=MockExamDetail)
async def get_exam(
    exam_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> MockExamDetail:
    return await MockExamService(session).get(user_id, exam_id)


@router.post("/{exam_id}/start", response_model=MockExamDetail)
async def start_exam(
    exam_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> MockExamDetail:
    return await MockExamService(session).start(user_id, exam_id)


@router.post("/{exam_id}/answer", response_model=MockExamDetail)
async def submit_answer(
    exam_id: uuid.UUID,
    payload: SubmitAnswerRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> MockExamDetail:
    return await MockExamService(session).submit_answer(user_id, exam_id, payload)


@router.post("/{exam_id}/submit", response_model=MockExamResults)
async def submit_exam(
    exam_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> MockExamResults:
    """Finalize and grade the exam. Idempotent on already-graded exams."""
    return await MockExamService(session).submit(user_id, exam_id)


@router.get("/{exam_id}/results", response_model=MockExamResults)
async def get_results(
    exam_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> MockExamResults:
    return await MockExamService(session).results(user_id, exam_id)
