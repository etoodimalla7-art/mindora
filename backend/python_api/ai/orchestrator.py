"""AI Orchestrator — routes each user message to the right tools.

Strategy:
  1. Run a deterministic heuristic classifier on the message (fast, cheap).
  2. Ask the LLM to confirm/refine the tool selection.
  3. Merge the two decisions (union, with priority on the heuristic).
  4. Execute the selected tools.
  5. Compose the final answer with the calculator result as ground truth.
"""
from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass, field
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage
from ai.tools import (
    CalculatorTool,
    CourseRagTool,
    GeneralChatTool,
    Tool,
    ToolContext,
    ToolResult,
)

logger = logging.getLogger(__name__)


@dataclass
class OrchestratorResult:
    text: str
    tools_used: list[dict]
    model: str | None = None
    provider: str | None = None
    usage: dict = field(default_factory=dict)
    reasoning: str | None = None


# Keywords that strongly suggest we should search the user's documents.
_COURSE_RAG_KEYWORDS = (
    # English
    "my course", "my notes", "my document", "my lesson", "my textbook",
    "my material", "my class", "my syllabus", "the chapter", "this chapter",
    "the lesson", "uploaded", "what does my", "in my course", "from my course",
    "according to my", "based on my", "in the notes", "in the document",
    # French
    "mon cours", "mes notes", "mon document", "ma leçon", "mon manuel",
    "ma matière", "ma classe", "le chapitre", "ce chapitre", "la leçon",
    "d'après mon", "selon mon", "dans mes notes", "dans le document",
    "dans mon cours",
)


_CLASSIFIER_SYSTEM = """You are a routing assistant for MINDORA, an academic tutor.

Decide which tools are needed to answer the student's message.

Available tools:
  - general_chat : general explanations, definitions, reasoning, teaching
  - calculator   : plain arithmetic evaluation only (e.g. "2+3", "sqrt(9)")
  - course_rag   : search and answer from the student's own uploaded documents.
                   Use this whenever the student mentions their course, notes,
                   lessons, chapters, uploaded materials, or asks
                   "what does my ... say".

Reply strictly with a JSON object:
{"intent": "<short>", "confidence": <0..1>, "tools": ["..."], "reasoning": "<short>"}

Rules:
- ALWAYS include general_chat unless the message is pure arithmetic.
- If the message is a bare arithmetic expression, include calculator.
- If ANY of these appear, include course_rag:
  my course, my notes, my document, my lesson, my textbook, uploaded,
  chapter, the document, mon cours, mes notes, le chapitre, etc.
- If unsure, include course_rag anyway — it degrades gracefully if no docs exist.
"""


class Orchestrator:
    """Classify → execute → compose."""

    def __init__(self, session: AsyncSession | None = None) -> None:
        self.session = session
        self.tools: dict[str, Tool] = {
            "general_chat": GeneralChatTool(),
            "calculator": CalculatorTool(),
        }
        if session is not None:
            self.tools["course_rag"] = CourseRagTool(session)

    async def run(self, ctx: ToolContext) -> OrchestratorResult:
        # 1. Heuristic classification (deterministic, no LLM call).
        heuristic_tools = self._heuristic_tools(ctx.message)

        # 2. LLM classification (may enrich or confirm).
        llm_decision = await self._classify(ctx.message)

        # 3. Merge: union of tools, filtered by availability.
        selected: list[str] = []
        for name in heuristic_tools + llm_decision.get("tools", []):
            if name in self.tools and name not in selected:
                selected.append(name)
        if "course_rag" in selected and "course_rag" not in self.tools:
            selected.remove("course_rag")
        if not selected:
            selected = ["general_chat"]

        logger.info(
            "orchestrator_tools selected=%s heuristic=%s llm=%s",
            selected,
            heuristic_tools,
            llm_decision.get("tools"),
        )

        # 4. Execute each tool.
        results: list[ToolResult] = []
        for name in selected:
            tool = self.tools[name]
            ctx.extras.setdefault("session", self.session)
            try:
                r = await tool.execute(ctx)
                results.append(r)
            except Exception as exc:  # noqa: BLE001
                logger.exception("tool_execution_failed name=%s", name)
                results.append(ToolResult(text="", tool_name=name, error=str(exc)))

        # 5. Compose.
        composed, model, provider, usage = await self._compose(ctx, results)

        tools_used = [
            {
                "name": r.tool_name,
                "error": r.error,
                "metadata": r.metadata or None,
            }
            for r in results
        ]

        return OrchestratorResult(
            text=composed,
            tools_used=tools_used,
            model=model,
            provider=provider,
            usage=usage or {},
            reasoning=llm_decision.get("reasoning"),
        )

    # ---------- Heuristic classifier ----------

    @staticmethod
    def _heuristic_tools(message: str) -> list[str]:
        tools: list[str] = ["general_chat"]
        low = message.lower()

        if _looks_like_arithmetic(message):
            tools.insert(0, "calculator")

        # Any course-RAG keyword → force course_rag.
        if any(kw in low for kw in _COURSE_RAG_KEYWORDS):
            tools.append("course_rag")

        return tools

    # ---------- LLM classifier ----------

    async def _classify(self, message: str) -> dict[str, Any]:
        provider = get_chat_provider()
        try:
            response = await provider.chat(
                [
                    ChatMessage(role="system", content=_CLASSIFIER_SYSTEM),
                    ChatMessage(role="user", content=message),
                ],
                temperature=0.0,
                json_mode=True,
                max_tokens=250,
            )
            data = _safe_json(response.content)
            if data and isinstance(data.get("tools"), list):
                return data
        except Exception as exc:  # noqa: BLE001
            logger.warning("intent_classification_failed error=%s", exc)

        return {"intent": "general", "confidence": 0.5, "tools": [], "reasoning": "llm failed"}

    # ---------- Composition ----------

    async def _compose(
        self,
        ctx: ToolContext,
        results: list[ToolResult],
    ) -> tuple[str, str | None, str | None, dict]:
        general = next(
            (r for r in results if r.tool_name == "general_chat" and r.text),
            None,
        )
        calc = next(
            (r for r in results if r.tool_name == "calculator" and r.text),
            None,
        )
        rag = next(
            (r for r in results if r.tool_name == "course_rag" and r.text),
            None,
        )

        # course_rag is authoritative when it produced text.
        if rag:
            prefix = ""
            if calc:
                prefix = f"**Computation**\n\n`{calc.text}`\n\n"
            return prefix + rag.text, rag.model, rag.provider, rag.usage

        # Pure general chat.
        if general and not calc:
            return general.text, general.model, general.provider, general.usage

        # Calc only.
        if calc and not general:
            return f"**Computation**\n\n`{calc.text}`", None, None, {}

        # Both calc and general: give the LLM the computed result as ground truth.
        if calc and general:
            provider = get_chat_provider()
            try:
                response = await provider.chat(
                    [
                        ChatMessage(
                            role="system",
                            content=(
                                "You are MINDORA, a patient academic tutor. "
                                "The calculator has already produced the result. "
                                "Explain the reasoning using the given value as fact. "
                                "Never recompute it yourself."
                            ),
                        ),
                        ChatMessage(
                            role="user",
                            content=(
                                f"Question: {ctx.message}\n\n"
                                f"Computed result: {calc.text}\n\n"
                                "Explain this result step by step."
                            ),
                        ),
                    ],
                    temperature=0.3,
                    max_tokens=1000,
                )
                composed = (
                    f"**Computation**\n\n`{calc.text}`\n\n"
                    f"**Explanation**\n\n{response.content}"
                )
                return composed, response.model, response.provider, response.usage or {}
            except Exception as exc:  # noqa: BLE001
                logger.warning("compose_calc_rerun_failed error=%s", exc)
                return (
                    f"**Computation**\n\n`{calc.text}`\n\n"
                    f"**Explanation**\n\n{general.text}",
                    general.model,
                    general.provider,
                    general.usage,
                )

        return (
            "I could not answer that right now. Please rephrase or try again.",
            None,
            None,
            {},
        )


# ---------- Helpers ----------

def _safe_json(text: str) -> dict | None:
    if not text:
        return None
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if not match:
            return None
        try:
            return json.loads(match.group(0))
        except json.JSONDecodeError:
            return None


def _looks_like_arithmetic(message: str) -> bool:
    s = message.strip().rstrip("?.! ")
    if not re.match(r"^[\s\d\.\+\-\*/\(\)\,%^a-zA-Z_]+$", s):
        return False
    return bool(re.search(r"[\+\-\*/%^\(\)]", s))
