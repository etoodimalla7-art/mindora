"""Chat service — persistence + orchestration glue."""
from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.integrations.ai.provider import ChatMessage
from app.models.conversation import Conversation, Message
from app.schemas.ai import ChatRequest, ChatResponse, MessageOut
from ai.orchestrator import Orchestrator
from ai.tools.base import ToolContext


class ChatService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.orchestrator = Orchestrator()

    async def send(
        self,
        user_id: uuid.UUID,
        payload: ChatRequest,
    ) -> ChatResponse:
        # 1. Load or create the conversation.
        conversation = await self._get_or_create_conversation(user_id, payload)

        # 2. Persist the user message.
        user_msg = Message(
            conversation_id=conversation.id,
            role="user",
            content=payload.message,
        )
        self.session.add(user_msg)
        await self.session.flush()

        # 3. Load recent history (excluding the just-saved user message).
        history = await self._recent_history(conversation.id)

        # 4. Run the orchestrator.
        ctx = ToolContext(
            user_id=str(user_id),
            message=payload.message,
            history=[ChatMessage(role=m.role, content=m.content) for m in history],
            subject=conversation.subject,
        )
        result = await self.orchestrator.run(ctx)

        # 5. Persist the assistant message.
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

        # 6. Update counters.
        conversation.message_count = (conversation.message_count or 0) + 2
        # Auto-title the conversation from the first user message.
        if conversation.message_count <= 2:
            conversation.title = _auto_title(payload.message)

        await self.session.commit()
        await self.session.refresh(assistant_msg)

        return ChatResponse(
            conversation_id=conversation.id,
            message=MessageOut.model_validate(assistant_msg),
            usage=result.usage or {},
        )

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

    # ---------- Internals ----------

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
