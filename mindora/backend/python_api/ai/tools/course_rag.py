"""Tool that answers questions using the student's own uploaded documents."""
from __future__ import annotations

import logging
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage
from ai.rag.retriever import RetrievedChunk, search_documents
from ai.tools.base import ToolContext, ToolResult

logger = logging.getLogger(__name__)

_SYSTEM = """You are MINDORA, an academic tutor.

You are given excerpts from the student's own course documents.
Use ONLY these excerpts as the source of truth. If the answer is not
covered, say so honestly and offer a general explanation marked as
"not from your documents".

Format:
- Start with a direct answer.
- Then provide a short explanation grounded in the excerpts.
- Quote short passages where helpful (in French quotes « »).
- Never invent details that are not in the excerpts.
"""


class CourseRagTool:
    name = "course_rag"
    description = (
        "Answer questions using the student's own uploaded course documents. "
        "Use when the student refers to their course, notes, lessons, or "
        "uploaded materials."
    )

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def execute(self, ctx: ToolContext) -> ToolResult:
        # The session lives in the context extras because Tool is stateless.
        session = ctx.extras.get("session")
        if not isinstance(session, AsyncSession):
            return ToolResult(
                text="",
                tool_name=self.name,
                error="Session unavailable.",
            )

        try:
            user_uuid = uuid.UUID(ctx.user_id)
        except (ValueError, TypeError):
            return ToolResult(
                text="",
                tool_name=self.name,
                error="Invalid user id.",
            )

        document_id = ctx.extras.get("document_id")

        try:
            hits = await search_documents(
                session,
                query=ctx.message,
                user_id=user_uuid,
                top_k=5,
                document_id=document_id,
            )
        except Exception as exc:  # noqa: BLE001
            logger.exception("course_rag_search_failed")
            return ToolResult(
                text="",
                tool_name=self.name,
                error=f"Search failed: {exc}",
            )

        if not hits:
            return ToolResult(
                text="",
                tool_name=self.name,
                metadata={"hits": 0},
            )

        # Build the prompt with the retrieved context.
        context_block = self._format_context(hits)
        user_prompt = (
            f"Student question:\n{ctx.message}\n\n"
            f"Excerpts from the student's course:\n\n{context_block}"
        )

        provider = get_chat_provider()
        try:
            response = await provider.chat(
                [
                    ChatMessage(role="system", content=_SYSTEM),
                    ChatMessage(role="user", content=user_prompt),
                ],
                temperature=0.2,
                max_tokens=1400,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error("course_rag_chat_failed error=%s", exc)
            return ToolResult(
                text="",
                tool_name=self.name,
                error=str(exc),
            )

        # Append a small source list.
        sources = self._format_sources(hits)
        text = f"{response.content}\n\n{sources}"

        return ToolResult(
            text=text,
            tool_name=self.name,
            model=response.model,
            provider=response.provider,
            usage=response.usage or {},
            metadata={
                "hits": len(hits),
                "document_ids": list({str(h.document_id) for h in hits}),
            },
        )

    # ---------- Formatting ----------

    @staticmethod
    def _format_context(hits: list[RetrievedChunk]) -> str:
        lines: list[str] = []
        for i, h in enumerate(hits, start=1):
            snippet = h.content.strip()
            if len(snippet) > 1200:
                snippet = snippet[:1200] + "…"
            lines.append(
                f"[Excerpt {i} · from « {h.document_title} » · "
                f"relevance {h.similarity:.2f}]\n{snippet}"
            )
        return "\n\n---\n\n".join(lines)

    @staticmethod
    def _format_sources(hits: list[RetrievedChunk]) -> str:
        if not hits:
            return ""
        seen: set[tuple[str, int]] = set()
        bullets: list[str] = []
        for h in hits:
            key = (str(h.document_id), h.chunk_index)
            if key in seen:
                continue
            seen.add(key)
            bullets.append(f"- *{h.document_title}* (chunk #{h.chunk_index})")
        return "**Sources**\n\n" + "\n".join(bullets)
