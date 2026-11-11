"""Study Groups REST endpoints (Phase 13)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query, Response, status

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.study_group import (
    GroupMessageCreate,
    GroupMessageOut,
    StudyGroupCreate,
    StudyGroupOut,
)
from app.services.study_group_service import StudyGroupService

router = APIRouter()


@router.post("", response_model=StudyGroupOut, status_code=status.HTTP_201_CREATED)
async def create_group(
    payload: StudyGroupCreate,
    session: SessionDep,
    user_id: CurrentUserId,
) -> StudyGroupOut:
    return await StudyGroupService(session).create_group(user_id, payload)


@router.get("", response_model=list[StudyGroupOut])
async def list_groups(
    session: SessionDep,
    user_id: CurrentUserId,
    subject: str | None = Query(default=None, max_length=80),
    exam_system: str | None = Query(default=None, max_length=40),
    exam_level: str | None = Query(default=None, max_length=40),
    search: str | None = Query(default=None, max_length=120),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> list[StudyGroupOut]:
    return await StudyGroupService(session).list_groups(
        subject=subject,
        exam_system=exam_system,
        exam_level=exam_level,
        search=search,
        limit=limit,
        offset=offset,
    )


@router.get("/{group_id}", response_model=StudyGroupOut)
async def get_group(
    group_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> StudyGroupOut:
    return await StudyGroupService(session).get_group(group_id)


@router.delete("/{group_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_group(
    group_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> Response:
    await StudyGroupService(session).delete_group(user_id, group_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/{group_id}/join", response_model=StudyGroupOut)
async def join_group(
    group_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> StudyGroupOut:
    return await StudyGroupService(session).join_group(user_id, group_id)


@router.post("/{group_id}/leave", status_code=status.HTTP_204_NO_CONTENT)
async def leave_group(
    group_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> Response:
    await StudyGroupService(session).leave_group(user_id, group_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/{group_id}/messages", response_model=list[GroupMessageOut])
async def list_messages(
    group_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
    limit: int = Query(default=50, ge=1, le=200),
) -> list[GroupMessageOut]:
    return await StudyGroupService(session).list_messages(
        user_id, group_id, limit=limit
    )


@router.post(
    "/{group_id}/messages",
    response_model=GroupMessageOut,
    status_code=status.HTTP_201_CREATED,
)
async def post_message(
    group_id: uuid.UUID,
    payload: GroupMessageCreate,
    session: SessionDep,
    user_id: CurrentUserId,
) -> GroupMessageOut:
    return await StudyGroupService(session).post_message(user_id, group_id, payload)
