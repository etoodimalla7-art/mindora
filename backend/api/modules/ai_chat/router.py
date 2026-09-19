from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.config import get_settings
from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.integrations.llm_provider import get_llm_provider
from api.integrations.speech_provider import get_speech_provider
from api.modules.ai_chat.orchestrator import ChatOrchestrator
from api.modules.ai_chat.repository import AiChatRepository
from api.modules.ai_chat.schemas import (
    ChatRequest, ChatResponseOut, ConversationOut, MessageOut, VisionChatResponseOut, VoiceChatResponseOut,
)
from api.modules.ai_chat.service import AiChatService
from api.modules.ai_chat.vision_input import extract_text_from_image
from api.modules.documents.repository import DocumentsRepository
from api.modules.users.models import User

router = APIRouter(prefix="/ai", tags=["ai"])


def get_service(db: AsyncSession = Depends(get_db)) -> AiChatService:
    settings = get_settings()
    documents_repo = DocumentsRepository(db)
    orchestrator = ChatOrchestrator(
        get_llm_provider(settings.llm_api_key),
        documents_repo.list_extracted_texts_for_user,
    )
    return AiChatService(
        AiChatRepository(db), orchestrator, get_speech_provider(), extract_text_from_image,
    )


@router.post("/chat")
async def chat(
    payload: ChatRequest,
    current_user: User = Depends(get_current_user),
    service: AiChatService = Depends(get_service),
):
    conversation, result = await service.send_message(
        str(current_user.id), payload.message, payload.conversation_id, payload.socratic_override,
    )
    return envelope(data=ChatResponseOut(
        conversation_id=str(conversation.id),
        reply=result.reply,
        intent=result.intent,
        tools_used=result.tools_used,
        source_document_id=result.source_document_id,
        style_preferences=result.style_preferences,
    ).model_dump())


@router.get("/conversations")
async def list_conversations(
    current_user: User = Depends(get_current_user),
    service: AiChatService = Depends(get_service),
):
    conversations = await service.list_conversations(str(current_user.id))
    return envelope(data=[ConversationOut.model_validate(orm_to_dict(c)).model_dump() for c in conversations])


@router.get("/conversations/{conversation_id}")
async def get_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    service: AiChatService = Depends(get_service),
):
    messages = await service.get_conversation_messages(conversation_id, str(current_user.id))
    return envelope(data=[MessageOut.model_validate(orm_to_dict(m)).model_dump() for m in messages])


@router.post("/voice")
async def voice(
    file: UploadFile = File(...),
    conversation_id: str | None = Form(default=None),
    current_user: User = Depends(get_current_user),
    service: AiChatService = Depends(get_service),
):
    audio_bytes = await file.read()
    conversation, result, transcript, audio_reply = await service.send_voice_message(
        str(current_user.id), audio_bytes, file.content_type or "audio/wav", conversation_id,
    )
    import base64
    return envelope(data=VoiceChatResponseOut(
        conversation_id=str(conversation.id),
        transcript=transcript,
        reply=result.reply,
        intent=result.intent,
        tools_used=result.tools_used,
        source_document_id=result.source_document_id,
        style_preferences=result.style_preferences,
        audio_reply_base64=base64.b64encode(audio_reply).decode("ascii") if audio_reply else None,
    ).model_dump())


@router.post("/vision")
async def vision(
    file: UploadFile = File(...),
    conversation_id: str | None = Form(default=None),
    current_user: User = Depends(get_current_user),
    service: AiChatService = Depends(get_service),
):
    image_bytes = await file.read()
    conversation, result, extracted_question, used_vision_model = await service.send_vision_message(
        str(current_user.id), image_bytes, file.content_type or "image/jpeg", conversation_id,
    )
    return envelope(data=VisionChatResponseOut(
        conversation_id=str(conversation.id),
        extracted_question=extracted_question,
        used_vision_model=used_vision_model,
        reply=result.reply,
        intent=result.intent,
        tools_used=result.tools_used,
        source_document_id=result.source_document_id,
        style_preferences=result.style_preferences,
    ).model_dump())
