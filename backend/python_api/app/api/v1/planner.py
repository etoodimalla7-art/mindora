"""Planner routes."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, status

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.planner import (
    ExamPlanCreate,
    SessionCompleteRequest,
    StudyPlanDetail,
    StudyPlanOut,
    StudySessionOut,
    SubjectPlanCreate,
)
from app.services.planner_service import PlannerService

router = APIRouter()


@router.post(
    "/exam",
    response_model=StudyPlanDetail,
    status_code=status.HTTP_201_CREATED,
)
async def create_exam_plan(
    payload: ExamPlanCreate, session: SessionDep, user_id: CurrentUserId
) -> StudyPlanDetail:
    return await PlannerService(session).create_exam_plan(user_id, payload)


@router.post(
    "/subject",
    response_model=StudyPlanDetail,
    status_code=status.HTTP_201_CREATED,
)
async def create_subject_plan(
    payload: SubjectPlanCreate, session: SessionDep, user_id: CurrentUserId
) -> StudyPlanDetail:
    return await PlannerService(session).create_subject_plan(user_id, payload)


@router.get("/plans", response_model=list[StudyPlanOut])
async def list_plans(
    session: SessionDep, user_id: CurrentUserId
) -> list[StudyPlanOut]:
    return await PlannerService(session).list_plans(user_id)


@router.get("/plans/{plan_id}", response_model=StudyPlanDetail)
async def get_plan(
    plan_id: uuid.UUID, session: SessionDep, user_id: CurrentUserId
) -> StudyPlanDetail:
    return await PlannerService(session).get_plan(user_id, plan_id)


@router.get("/sessions", response_model=list[StudySessionOut])
async def upcoming_sessions(
    session: SessionDep, user_id: CurrentUserId
) -> list[StudySessionOut]:
    return await PlannerService(session).upcoming_sessions(user_id)


@router.post("/sessions/{session_id}/start", response_model=StudySessionOut)
async def start_session(
    session_id: uuid.UUID, session: SessionDep, user_id: CurrentUserId
) -> StudySessionOut:
    return await PlannerService(session).start_session(user_id, session_id)


@router.post("/sessions/{session_id}/complete", response_model=StudySessionOut)
async def complete_session(
    session_id: uuid.UUID,
    payload: SessionCompleteRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> StudySessionOut:
    return await PlannerService(session).complete_session(user_id, session_id, payload)
