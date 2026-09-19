from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.ai_chat.models import Conversation, Message


class AiChatRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_conversation(self, user_id: str, title: str | None = None) -> Conversation:
        conversation = Conversation(user_id=to_uuid(user_id), title=title)
        self.db.add(conversation)
        await self.db.commit()
        await self.db.refresh(conversation)
        return conversation

    async def get_owned_conversation(self, conversation_id: str, user_id: str) -> Conversation | None:
        result = await self.db.execute(
            select(Conversation)
            .where(Conversation.id == to_uuid(conversation_id))
            .where(Conversation.user_id == to_uuid(user_id))
        )
        return result.scalar_one_or_none()

    async def add_message(
        self, conversation_id: str, role: str, content: str, tool_trace: dict | None = None
    ) -> Message:
        message = Message(
            conversation_id=to_uuid(conversation_id), role=role, content=content, tool_trace=tool_trace or {},
        )
        self.db.add(message)
        await self.db.commit()
        await self.db.refresh(message)
        return message

    async def list_messages(self, conversation_id: str) -> list[Message]:
        result = await self.db.execute(
            select(Message)
            .where(Message.conversation_id == to_uuid(conversation_id))
            .order_by(Message.created_at)
        )
        return list(result.scalars().all())

    async def list_conversations(self, user_id: str) -> list[Conversation]:
        result = await self.db.execute(
            select(Conversation)
            .where(Conversation.user_id == to_uuid(user_id))
            .order_by(Conversation.created_at.desc())
        )
        return list(result.scalars().all())

    async def update_style_preferences(self, conversation_id: str, preferences: dict) -> None:
        conversation = await self.db.get(Conversation, to_uuid(conversation_id))
        if conversation:
            conversation.style_preferences = preferences
            await self.db.commit()
