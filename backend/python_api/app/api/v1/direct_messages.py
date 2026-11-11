"""Direct 1-to-1 messaging endpoints (Phase 13.7)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query, status

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.direct_message import (
    DirectConversationCreate,
    DirectConversationOut,
    DirectMessageCreate,
    DirectMessageOut,
)
from app.services.direct_message_service import DirectMessageService

router = APIRouter()


@router.get("", response_model=list[DirectConversationOut])
async def list_conversations(
    session: SessionDep,
    user_id: CurrentUserId,
) -> list[DirectConversationOut]:
    return await DirectMessageService(session).list_conversations(user_id)


@router.post(
    "",
    response_model=DirectConversationOut,
    status_code=status.HTTP_201_CREATED,
)
async def get_or_create(
    payload: DirectConversationCreate,
    session: SessionDep,
    user_id: CurrentUserId,
) -> DirectConversationOut:
    return await DirectMessageService(session).get_or_create(
        user_id, payload.peer_user_id
    )


@router.get("/{conversation_id}", response_model=DirectConversationOut)
async def get_conversation(
    conversation_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> DirectConversationOut:
    return await DirectMessageService(session).get_conversation(
        user_id, conversation_id
    )


@router.get("/{conversation_id}/messages", response_model=list[DirectMessageOut])
async def list_messages(
    conversation_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
    limit: int = Query(default=50, ge=1, le=200),
) -> list[DirectMessageOut]:
    return await DirectMessageService(session).list_messages(
        user_id, conversation_id, limit=limit
    )


@router.post(
    "/{conversation_id}/messages",
    response_model=DirectMessageOut,
    status_code=status.HTTP_201_CREATED,
)
async def post_message(
    conversation_id: uuid.UUID,
    payload: DirectMessageCreate,
    session: SessionDep,
    user_id: CurrentUserId,
) -> DirectMessageOut:
    return await DirectMessageService(session).post_message(
        user_id, conversation_id, payload
    )
