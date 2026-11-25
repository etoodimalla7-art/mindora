"""Direct 1-to-1 messaging service (Phase 13.7)."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.errors import ForbiddenError, NotFoundError
from app.models.direct_message import DirectConversation, DirectMessage
from app.models.user import User
from app.schemas.direct_message import (
    DirectConversationOut,
    DirectMessageCreate,
    DirectMessageOut,
    DirectPeerOut,
)

logger = logging.getLogger(__name__)


class DirectMessageService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Conversations ----------

    async def get_or_create(
        self, user_id: uuid.UUID, peer_user_id: uuid.UUID
    ) -> DirectConversationOut:
        if user_id == peer_user_id:
            raise ForbiddenError("You cannot chat with yourself.")

        peer = (
            await self.session.execute(
                select(User).where(User.id == peer_user_id, User.is_active.is_(True))
            )
        ).scalar_one_or_none()
        if peer is None:
            raise NotFoundError("User not found.")

        # Normalize pair order (smaller UUID first) so the pair is unique.
        a, b = sorted([user_id, peer_user_id], key=str)
        conv = (
            await self.session.execute(
                select(DirectConversation).where(
                    DirectConversation.user_a_id == a,
                    DirectConversation.user_b_id == b,
                )
            )
        ).scalar_one_or_none()

        if conv is None:
            conv = DirectConversation(user_a_id=a, user_b_id=b)
            self.session.add(conv)
            await self.session.commit()
            await self.session.refresh(conv)

        return await self._to_conversation_out(conv, user_id)

    async def list_conversations(
        self, user_id: uuid.UUID
    ) -> list[DirectConversationOut]:
        stmt = (
            select(DirectConversation)
            .where(
                or_(
                    DirectConversation.user_a_id == user_id,
                    DirectConversation.user_b_id == user_id,
                )
            )
            .order_by(
                DirectConversation.last_message_at.desc().nullslast(),
                DirectConversation.created_at.desc(),
            )
        )
        rows = list((await self.session.execute(stmt)).scalars().all())
        return [await self._to_conversation_out(c, user_id) for c in rows]

    async def get_conversation(
        self, user_id: uuid.UUID, conversation_id: uuid.UUID
    ) -> DirectConversationOut:
        conv = await self._get_or_404(conversation_id)
        self._assert_participant(conv, user_id)
        return await self._to_conversation_out(conv, user_id)

    # ---------- Messages ----------

    async def list_messages(
        self,
        user_id: uuid.UUID,
        conversation_id: uuid.UUID,
        *,
        limit: int = 50,
        before: datetime | None = None,
    ) -> list[DirectMessageOut]:
        conv = await self._get_or_404(conversation_id)
        self._assert_participant(conv, user_id)

        # Mark received messages as read
        now = datetime.utcnow()
        unread = (
            await self.session.execute(
                select(DirectMessage).where(
                    DirectMessage.conversation_id == conversation_id,
                    DirectMessage.sender_id != user_id,
                    DirectMessage.read_at.is_(None),
                )
            )
        ).scalars().all()
        for m in unread:
            m.read_at = now
        if unread:
            await self.session.commit()

        stmt = (
            select(DirectMessage)
            .options(selectinload(DirectMessage.sender))
            .where(DirectMessage.conversation_id == conversation_id)
        )
        if before:
            stmt = stmt.where(DirectMessage.created_at < before)
        stmt = stmt.order_by(DirectMessage.created_at.desc()).limit(limit)

        rows = list((await self.session.execute(stmt)).scalars().all())
        rows.reverse()
        return [self._message_to_out(m) for m in rows]

    async def post_message(
        self,
        user_id: uuid.UUID,
        conversation_id: uuid.UUID,
        payload: DirectMessageCreate,
    ) -> DirectMessageOut:
        conv = await self._get_or_404(conversation_id)
        self._assert_participant(conv, user_id)

        msg = DirectMessage(
            conversation_id=conversation_id,
            sender_id=user_id,
            content=payload.content.strip(),
        )
        self.session.add(msg)
        conv.last_message_at = datetime.utcnow()
        await self.session.commit()
        await self.session.refresh(msg)

        loaded = (
            await self.session.execute(
                select(DirectMessage)
                .options(selectinload(DirectMessage.sender))
                .where(DirectMessage.id == msg.id)
            )
        ).scalar_one()
        return self._message_to_out(loaded)

    # ---------- Helpers ----------

    async def _get_or_404(
        self, conversation_id: uuid.UUID
    ) -> DirectConversation:
        conv = (
            await self.session.execute(
                select(DirectConversation).where(
                    DirectConversation.id == conversation_id
                )
            )
        ).scalar_one_or_none()
        if conv is None:
            raise NotFoundError("Conversation not found.")
        return conv

    @staticmethod
    def _assert_participant(
        conv: DirectConversation, user_id: uuid.UUID
    ) -> None:
        if conv.user_a_id != user_id and conv.user_b_id != user_id:
            raise ForbiddenError("You are not a participant in this conversation.")

    async def _to_conversation_out(
        self, conv: DirectConversation, user_id: uuid.UUID
    ) -> DirectConversationOut:
        peer = conv.user_b if conv.user_a_id == user_id else conv.user_a
        peer_profile = getattr(peer, "profile", None)
        avatar = peer_profile.avatar_url if peer_profile else None

        # Last message preview + unread count
        last_msg = (
            await self.session.execute(
                select(DirectMessage)
                .where(DirectMessage.conversation_id == conv.id)
                .order_by(DirectMessage.created_at.desc())
                .limit(1)
            )
        ).scalar_one_or_none()

        unread = (
            await self.session.execute(
                select(func.count(DirectMessage.id)).where(
                    DirectMessage.conversation_id == conv.id,
                    DirectMessage.sender_id != user_id,
                    DirectMessage.read_at.is_(None),
                )
            )
        ).scalar_one()

        return DirectConversationOut(
            id=conv.id,
            peer=DirectPeerOut(
                user_id=peer.id,
                full_name=peer.full_name,
                email=peer.email,
                avatar_url=avatar,
            ),
            last_message_at=conv.last_message_at,
            last_message_preview=(
                last_msg.content[:80] if last_msg else None
            ),
            unread_count=unread,
            created_at=conv.created_at,
        )

    @staticmethod
    def _message_to_out(m: DirectMessage) -> DirectMessageOut:
        out = DirectMessageOut.model_validate(m)
        if m.sender is not None:
            out.sender_name = m.sender.full_name or m.sender.email
        return out
