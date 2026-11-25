"""AI chat endpoints."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Response, status
from fastapi.responses import StreamingResponse

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.ai import (
    ChatRequest,
    ChatResponse,
    ConversationDetail,
    ConversationOut,
    MessageOut,
    VisionAnalyzeRequest,
    VoiceAnalyzeRequest,
    VoiceResponse,
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


@router.post("/vision", response_model=ChatResponse, status_code=status.HTTP_201_CREATED)
async def vision_analyze(
    payload: VisionAnalyzeRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> ChatResponse:
    """Analyze an image / exercise photo with Gemini Vision."""
    chat_payload = ChatRequest(
        message=payload.prompt,
        image_base64=payload.image_base64,
        image_mime_type=payload.image_mime_type,
        subject=payload.subject,
        conversation_id=payload.conversation_id,
        context_type="vision",
    )
    return await ChatService(session).send(user_id, chat_payload)


@router.post("/voice", response_model=VoiceResponse, status_code=status.HTTP_201_CREATED)
async def voice_analyze(
    payload: VoiceAnalyzeRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> VoiceResponse:
    """Process a speech-to-text transcript and return a tutor reply + TTS metadata."""
    chat_payload = ChatRequest(
        message=payload.transcript.strip(),
        subject=payload.subject,
        conversation_id=payload.conversation_id,
        context_type="voice",
    )
    result = await ChatService(session).send(user_id, chat_payload)
    tts_locale = "fr-FR" if payload.language == "fr" else "en-GB"
    # Strip heavy markdown symbols for clean spoken TTS playback
    spoken = (
        result.message.content.replace("**", "")
        .replace("##", "")
        .replace("#", "")
        .replace("`", "")
        .strip()
    )
    return VoiceResponse(
        conversation_id=result.conversation_id,
        message=result.message,
        usage=result.usage,
        tts_text=spoken,
        tts_locale=tts_locale,
    )


@router.post("/chat/stream")
async def chat_stream(
    payload: ChatRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> StreamingResponse:
    """Server-Sent Events stream.

    Emits:
      - event: meta  → {"conversation_id": "..."}
      - event: token → {"text": "chunk"}
      - event: done  → {"message_id": "...", "tools_used": [...], ...}
      - event: error → {"message": "..."}
    """
    service = ChatService(session)
    generator = service.send_stream(user_id, payload)

    return StreamingResponse(
        generator,
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache, no-transform",
            "X-Accel-Buffering": "no",
            "Connection": "keep-alive",
        },
    )


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
) -> Response:
    await ChatService(session).delete_conversation(user_id, conversation_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
