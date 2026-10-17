"""Chat service — persistence + orchestration glue (streaming aware)."""
from __future__ import annotations

import asyncio

import json
import logging
import uuid
from collections.abc import AsyncIterator

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.sse import sse_event, sse_ping
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
        """Yield SSE-formatted chunks with keep-alive + timeout + error recovery.

        Hardening vs previous version:
        - overall timeout (90s) → emits event:error instead of hanging forever
        - keep-alive ping every 15s → prevents Render/proxy 60s cut
        - all exceptions caught → emits event:error, never crashes generator
        - emits final `done` even on error so client can complete its Completer
        """
        import time

        TIMEOUT_SECONDS = 90
        conversation = None
        assistant_msg = None
        collected_text = ""

        try:
            # Step 1 — conversation + user message
            conversation = await self._get_or_create_conversation(user_id, payload)
            user_msg = Message(
                conversation_id=conversation.id,
                role="user",
                content=payload.message,
            )
            self.session.add(user_msg)
            await self.session.flush()
            await self.session.commit()

            yield sse_event(
                "meta", {"conversation_id": str(conversation.id)}
            )

            # Step 2 — decide stream vs fallback
            should_stream = await self._should_stream(payload.message)

            if not should_stream:
                # Fallback to non-streaming orchestrator.
                # Use a SEPARATE session to avoid conflicts with the outer one.
                from app.db.session import AsyncSessionLocal

                logger.info(
                    "chat_stream_fallback_start msg_len=%d",
                    len(payload.message),
                )

                history = await self._recent_history(conversation.id)
                try:
                    async with AsyncSessionLocal() as orch_session:
                        orch = Orchestrator(orch_session)
                        ctx = ToolContext(
                            user_id=str(user_id),
                            message=payload.message,
                            history=[
                                ChatMessage(role=m.role, content=m.content)
                                for m in history
                            ],
                            subject=conversation.subject,
                            extras={"session": orch_session},
                        )
                        logger.info("chat_stream_orchestrator_run_start")
                        # Shorter timeout for the tool fallback (30s)
                        result = await asyncio.wait_for(
                            orch.run(ctx),
                            timeout=30,
                        )
                        logger.info(
                            "chat_stream_orchestrator_run_done text_len=%d tools=%s",
                            len(result.text or ""),
                            [t.get("name") for t in (result.tools_used or [])],
                        )
                except asyncio.TimeoutError:
                    logger.error("chat_stream_orchestrator_timeout_30s")
                    yield sse_event("error", {
                        "message": "L'analyse de vos documents prend trop de temps. Réessayez."
                    })
                    yield sse_event("done", {
                        "message_id": "",
                        "tools_used": [],
                        "model": None,
                        "provider": None,
                        "usage": {},
                    })
                    return
                except Exception as exc:
                    logger.exception("chat_stream_orchestrator_failed: %s", exc)
                    yield sse_event("error", {
                        "message": f"AI error: {exc.__class__.__name__}"
                    })
                    yield sse_event("done", {
                        "message_id": "",
                        "tools_used": [],
                        "model": None,
                        "provider": None,
                        "usage": {},
                    })
                    return

                # Persist assistant message on the OUTER session
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

                yield sse_event("token", {"text": result.text})
                yield sse_event("done", {
                    "message_id": str(assistant_msg.id),
                    "tools_used": result.tools_used,
                    "model": result.model,
                    "provider": result.provider,
                    "usage": result.usage or {},
                })
                return

            # Step 3 — pure streaming path with keep-alive
            history = await self._recent_history(conversation.id)
            provider = get_chat_provider()
            messages = [
                ChatMessage(role=m.role, content=m.content) for m in history
            ] + [ChatMessage(role="user", content=payload.message)]

            start = time.monotonic()
            last_ping = start
            stream_iter = provider.chat_stream(messages)

            try:
                async for token in _iter_with_timeout(
                    stream_iter, TIMEOUT_SECONDS - (time.monotonic() - start)
                ):
                    if token:
                        collected_text += token
                        yield sse_event("token", {"text": token})

                    # keep-alive
                    now = time.monotonic()
                    if now - last_ping >= 15:
                        yield sse_ping()
                        last_ping = now

                    # global timeout check
                    if (now - start) >= TIMEOUT_SECONDS:
                        raise asyncio.TimeoutError("Stream exceeded 90s")

            except asyncio.TimeoutError:
                logger.warning("chat_stream timeout after 90s")
                yield sse_event("error", {
                    "message": "The AI took too long to respond. Please retry."
                })

            # Persist assistant message even if empty (so history is coherent)
            assistant_msg = Message(
                conversation_id=conversation.id,
                role="assistant",
                content=collected_text or "(no response)",
                tools_used=[],
                model=provider.default_model,
                provider=provider.name,
            )
            self.session.add(assistant_msg)
            conversation.message_count = (conversation.message_count or 0) + 2
            if conversation.message_count <= 2:
                conversation.title = _auto_title(payload.message)
            await self.session.commit()
            await self.session.refresh(assistant_msg)

            yield sse_event("done", {
                "message_id": str(assistant_msg.id),
                "tools_used": [],
                "model": provider.default_model,
                "provider": provider.name,
                "usage": {},
            })

        except Exception as exc:  # noqa: BLE001
            logger.exception("chat_stream fatal error: %s", exc)
            try:
                yield sse_event("error", {
                    "message": f"Internal error: {exc.__class__.__name__}"
                })
            except Exception:
                pass
            # Always emit done so client's Completer resolves
            try:
                yield sse_event("done", {
                    "message_id": "",
                    "tools_used": [],
                    "model": None,
                    "provider": None,
                    "usage": {},
                })
            except Exception:
                pass


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
async def _iter_with_timeout(iterator, timeout: float):
    """Wrap an async iterator with an overall timeout."""
    deadline = asyncio.get_event_loop().time() + max(timeout, 1.0)
    async for item in iterator:
        if asyncio.get_event_loop().time() >= deadline:
            raise asyncio.TimeoutError()
        yield item
