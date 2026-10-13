"""AI chat endpoints."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, status

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.ai import (
    ChatRequest,
    ChatResponse,
    ConversationDetail,
    ConversationOut,
    MessageOut,
)
from app.services.chat_service import ChatService

router = APIRouter()


@router.post("/chat", response_model=ChatResponse, status_code=status.HTTP_201_CREATED)
async def chat(
    payload: ChatRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> ChatResponse:
    return await ChatService(session).send(user_id, payload)


@router.get("/conversations", response_model=list[ConversationOut])
async def list_conversations(
    session: SessionDep, user_id: CurrentUserId
) -> list[ConversationOut]:
    rows = await ChatService(session).list_conversations(user_id)
    return [ConversationOut.model_validate(r) for r in rows]


@router.get("/conversations/{conversation_id}", response_model=ConversationDetail)
async def get_conversation(
    conversation_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> ConversationDetail:
    conv = await ChatService(session).get_conversation(user_id, conversation_id)
    return ConversationDetail(
        **ConversationOut.model_validate(conv).model_dump(),
        messages=[MessageOut.model_validate(m) for m in (conv.messages or [])],
    )


@router.delete(
    "/conversations/{conversation_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_conversation(
    conversation_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
):
    from fastapi import Response

    await ChatService(session).delete_conversation(user_id, conversation_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
