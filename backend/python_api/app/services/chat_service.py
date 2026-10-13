"""Chat service — persistence + orchestration glue (streaming aware)."""
from __future__ import annotations

import json
import logging
import uuid
from collections.abc import AsyncIterator

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage
from app.models.conversation import Conversation, Message
from app.schemas.ai import ChatRequest, ChatResponse, MessageOut
from ai.orchestrator import Orchestrator
from ai.tools.base import ToolContext

logger = logging.getLogger(__name__)


class ChatService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.orchestrator = Orchestrator(session)

    # ---------- Non-streaming ----------

    async def send(
        self,
        user_id: uuid.UUID,
        payload: ChatRequest,
    ) -> ChatResponse:
        conversation = await self._get_or_create_conversation(user_id, payload)

        user_msg = Message(
            conversation_id=conversation.id,
            role="user",
            content=payload.message,
        )
        self.session.add(user_msg)
        await self.session.flush()

        history = await self._recent_history(conversation.id)

        ctx = ToolContext(
            user_id=str(user_id),
            message=payload.message,
            history=[ChatMessage(role=m.role, content=m.content) for m in history],
            subject=conversation.subject,
            extras={"session": self.session},
        )
        result = await self.orchestrator.run(ctx)

        assistant_msg = Message(
            conversation_id=conversation.id,
            role="assistant",
            content=result.text,
            tools_used=result.tools_used,
            model=result.model,
            provider=result.provider,
            metadata_json={"reasoning": result.reasoning},
        )
        self.session.add(assistant_msg)

        conversation.message_count = (conversation.message_count or 0) + 2
        if conversation.message_count <= 2:
            conversation.title = _auto_title(payload.message)

        await self.session.commit()
        await self.session.refresh(assistant_msg)

        return ChatResponse(
            conversation_id=conversation.id,
            message=MessageOut.model_validate(assistant_msg),
            usage=result.usage or {},
        )

    # ---------- Streaming ----------

    async def send_stream(
        self,
        user_id: uuid.UUID,
        payload: ChatRequest,
    ) -> AsyncIterator[str]:
        """Yield SSE-formatted chunks: `data: {json}\\n\\n`.

        Flow:
          1. Create / fetch conversation, persist the user message.
          2. Emit a `meta` event with the conversation id.
          3. Stream tokens from Gemini.
          4. On completion, persist the assistant message and emit `done`.

        If the orchestrator would pick any tool other than general_chat,
        we fall back to the non-streaming pipeline and emit the result in
        a single chunk (tools like course_rag are fast anyway).
        """
        conversation = await self._get_or_create_conversation(user_id, payload)

        user_msg = Message(
            conversation_id=conversation.id,
            role="user",
            content=payload.message,
        )
        self.session.add(user_msg)
        await self.session.flush()
        await self.session.commit()

        # Emit meta immediately so the client has the conversation id.
        yield _sse(
            "meta",
            {"conversation_id": str(conversation.id)},
        )

        # Decide: stream or not?
        should_stream = await self._should_stream(payload.message)
        if not should_stream:
            # Fallback to the non-streaming orchestrator and emit once.
            history = await self._recent_history(conversation.id)
            ctx = ToolContext(
                user_id=str(user_id),
                message=payload.message,
                history=[
                    ChatMessage(role=m.role, content=m.content) for m in history
                ],
                subject=conversation.subject,
                extras={"session": self.session},
            )
            result = await self.orchestrator.run(ctx)
            assistant_msg = Message(
                conversation_id=conversation.id,
                role="assistant",
                content=result.text,
                tools_used=result.tools_used,
                model=result.model,
                provider=result.provider,
                metadata_json={"reasoning": result.reasoning},
            )
            self.session.add(assistant_msg)
            conversation.message_count = (conversation.message_count or 0) + 2
            if conversation.message_count <= 2:
                conversation.title = _auto_title(payload.message)
            await self.session.commit()
            await self.session.refresh(assistant_msg)

            yield _sse("token", {"text": result.text})
            yield _sse(
                "done",
                {
                    "message_id": str(assistant_msg.id),
                    "tools_used": result.tools_used,
                    "model": result.model,
                    "provider": result.provider,
                    "usage": result.usage or {},
                },
            )
            return

        # Streaming path — pure general_chat.
        history = await self._recent_history(conversation.id)
        provider = get_chat_provider()

        system_instruction = (
            "You are MINDORA, a patient academic tutor for students in "
            "Cameroon. Answer clearly in the same language as the student. "
            "Show reasoning step by step for math and science. Never invent "
            "citations. Keep answers structured: short intro, main "
            "explanation, brief recap."
        )
        messages: list[ChatMessage] = [
            ChatMessage(role="system", content=system_instruction)
        ]
        for m in history[-12:]:
            messages.append(ChatMessage(role=m.role, content=m.content))
        messages.append(ChatMessage(role="user", content=payload.message))

        full_text_parts: list[str] = []
        try:
            async for chunk in provider.chat_stream(messages, temperature=0.5):
                full_text_parts.append(chunk)
                yield _sse("token", {"text": chunk})
        except Exception as exc:  # noqa: BLE001
            logger.exception("stream_failed")
            yield _sse(
                "error",
                {"message": "The AI service is temporarily unavailable."},
            )
            return

        full_text = "".join(full_text_parts)
        assistant_msg = Message(
            conversation_id=conversation.id,
            role="assistant",
            content=full_text,
            tools_used=[{"name": "general_chat", "error": None, "metadata": None}],
            model=provider.default_model,
            provider=provider.name,
            metadata_json={"streamed": True},
        )
        self.session.add(assistant_msg)
        conversation.message_count = (conversation.message_count or 0) + 2
        if conversation.message_count <= 2:
            conversation.title = _auto_title(payload.message)
        await self.session.commit()
        await self.session.refresh(assistant_msg)

        yield _sse(
            "done",
            {
                "message_id": str(assistant_msg.id),
                "tools_used": [{"name": "general_chat", "error": None, "metadata": None}],
                "model": provider.default_model,
                "provider": provider.name,
                "usage": {},
            },
        )

    # ---------- Routing heuristic ----------

    async def _should_stream(self, message: str) -> bool:
        """Stream only if the message doesn't need course_rag or calculator.

        Reuses the orchestrator's deterministic heuristic for consistency.
        """
        from ai.orchestrator import Orchestrator as _O

        tools = _O._heuristic_tools(message)
        return tools == ["general_chat"]

    # ---------- Persistence helpers ----------

    async def list_conversations(
        self, user_id: uuid.UUID
    ) -> list[Conversation]:
        stmt = (
            select(Conversation)
            .where(
                Conversation.user_id == user_id,
                Conversation.deleted_at.is_(None),
            )
            .order_by(Conversation.updated_at.desc())
        )
        return list((await self.session.execute(stmt)).scalars().all())

    async def get_conversation(
        self, user_id: uuid.UUID, conversation_id: uuid.UUID
    ) -> Conversation:
        stmt = select(Conversation).where(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id,
            Conversation.deleted_at.is_(None),
        )
        conv = (await self.session.execute(stmt)).scalar_one_or_none()
        if not conv:
            raise NotFoundError("Conversation not found.")
        return conv

    async def delete_conversation(
        self, user_id: uuid.UUID, conversation_id: uuid.UUID
    ) -> None:
        conv = await self.get_conversation(user_id, conversation_id)
        await self.session.delete(conv)
        await self.session.commit()

    async def _get_or_create_conversation(
        self, user_id: uuid.UUID, payload: ChatRequest
    ) -> Conversation:
        if payload.conversation_id:
            return await self.get_conversation(user_id, payload.conversation_id)

        conv = Conversation(
            user_id=user_id,
            title=_auto_title(payload.message),
            subject=payload.subject,
            context_type=payload.context_type,
            context_id=payload.context_id,
        )
        self.session.add(conv)
        await self.session.flush()
        return conv

    async def _recent_history(self, conversation_id: uuid.UUID) -> list[Message]:
        stmt = (
            select(Message)
            .where(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.desc())
            .limit(20)
        )
        rows = list((await self.session.execute(stmt)).scalars().all())
        rows.reverse()
        return rows


def _auto_title(text: str) -> str:
    s = " ".join(text.strip().split())
    if len(s) <= 60:
        return s or "New conversation"
    return s[:57] + "..."


def _sse(event: str, data: dict) -> str:
    """Format a single SSE message."""
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"
