"""General conversation tool — reads system prompt from AIConfig DB (Phase 4)."""
from __future__ import annotations

import logging

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage
from ai.tools.base import ToolContext, ToolResult

logger = logging.getLogger(__name__)

# Fallback if DB has no config (should never happen after migration 0020)
_FALLBACK_SYSTEM = """You are MINDORA, a patient academic tutor for students in Cameroon.
You answer questions clearly, in the same language as the student.
You show your reasoning step by step for math and science.
You never invent citations. If you are not sure about a fact, say so.
You keep answers structured: short intro, main explanation, brief recap.
Never mention that you are an AI language model. Just teach."""


async def _load_active_prompt(session: AsyncSession | None) -> tuple[str, str, float, int]:
    """Return (prompt, model, temperature, max_tokens) from AIConfig.

    Falls back to the hardcoded prompt if the DB is unavailable or empty.
    """
    if session is None:
        return (_FALLBACK_SYSTEM, "", 0.5, 1200)

    try:
        from app.models.ai_config import AIConfig
        cfg = (
            await session.execute(
                select(AIConfig).where(AIConfig.is_active.is_(True)).limit(1)
            )
        ).scalar_one_or_none()
        if cfg is None:
            return (_FALLBACK_SYSTEM, "", 0.5, 1200)
        return (
            cfg.system_prompt or _FALLBACK_SYSTEM,
            cfg.model or "",
            cfg.temperature if cfg.temperature is not None else 0.5,
            cfg.max_tokens or 1200,
        )
    except Exception as exc:  # noqa: BLE001
        logger.warning("ai_config_load_failed error=%s", exc)
        return (_FALLBACK_SYSTEM, "", 0.5, 1200)


class GeneralChatTool:
    name = "general_chat"
    description = (
        "Answer general academic questions using the language model's own "
        "knowledge. Use for explanations, definitions, worked examples, "
        "clarifications that do not require looking up the student's files."
    )

    async def execute(self, ctx: ToolContext) -> ToolResult:
        provider = get_chat_provider()

        # Load the live config from DB
        session = ctx.extras.get("session") if ctx.extras else None
        prompt, model, temperature, max_tokens = await _load_active_prompt(session)

        messages: list[ChatMessage] = [ChatMessage(role="system", content=prompt)]
        for m in ctx.history[-12:]:
            messages.append(m)

        messages.append(
            ChatMessage(
                role="user",
                content=ctx.message,
                image_base64=ctx.image_base64,
                image_mime_type=ctx.image_mime_type,
            )
        )

        try:
            response = await provider.chat(
                messages,
                model=model or None,
                temperature=temperature,
                max_tokens=max_tokens,
            )
            return ToolResult(
                text=response.content,
                tool_name=self.name,
                model=response.model,
                provider=response.provider,
                usage=response.usage or {},
            )
        except Exception as exc:  # noqa: BLE001
            logger.exception("general_chat_failed")
            return ToolResult(
                text="I could not generate a response right now. Please try again.",
                tool_name=self.name,
                error=str(exc),
            )
