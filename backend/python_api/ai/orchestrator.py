"""AI Orchestrator — routes each user message to the right tools."""
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


_CLASSIFIER_SYSTEM = """You are a routing assistant.
Given a student message, decide which tools are needed to answer well.
Available tools:
  - general_chat : general explanations, definitions, reasoning, teaching
  - calculator   : plain arithmetic evaluation only
  - course_rag   : search and answer from the student's own uploaded documents
                   (use when the student refers to their course, notes,
                   lessons, chapters, or uploaded materials)

Reply strictly with a JSON object:
{"intent": "<short label>", "confidence": <0..1>, "tools": ["..."], "reasoning": "<short>"}

Rules:
- ALWAYS include general_chat unless the message is a pure calculation.
- If the message is a bare arithmetic expression, include calculator.
- If the message mentions the student's course, notes, lessons, chapter,
  "mon cours", "mes notes", "le chapitre", include course_rag.
- Keep tool list short. Never include a tool not in the list.
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
        # 1. Classify.
        decision = await self._classify(ctx.message)
        selected = [t for t in decision.get("tools", []) if t in self.tools]
        # course_rag is only available if we have a session.
        if "course_rag" in selected and "course_rag" not in self.tools:
            selected.remove("course_rag")
        if not selected:
            selected = ["general_chat"]

        # 2. Execute tools, collecting results.
        results: list[ToolResult] = []
        for name in selected:
            tool = self.tools[name]
            # Make session available to tools that need it.
            ctx.extras.setdefault("session", self.session)
            try:
                r = await tool.execute(ctx)
                results.append(r)
            except Exception as exc:  # noqa: BLE001
                logger.exception("tool_execution_failed name=%s", name)
                results.append(ToolResult(text="", tool_name=name, error=str(exc)))

        # 3. Compose the final answer.
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
            reasoning=decision.get("reasoning"),
        )

    # ---------- Classification ----------

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
                max_tokens=200,
            )
            data = _safe_json(response.content)
            if data and isinstance(data.get("tools"), list):
                return data
        except Exception as exc:  # noqa: BLE001
            logger.warning("intent_classification_failed error=%s", exc)

        # Fallback heuristic.
        tools = ["general_chat"]
        low = message.lower()
        if _looks_like_arithmetic(message):
            tools.insert(0, "calculator")
        if any(k in low for k in ("my course", "my notes", "mon cours", "mes notes",
                                  "le chapitre", "the chapter", "lesson", "leçon",
                                  "uploaded", "document")):
            tools.append("course_rag")
        return {
            "intent": "general",
            "confidence": 0.5,
            "tools": tools,
            "reasoning": "heuristic",
        }

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

        # Preferred: course_rag gives a grounded answer.
        if rag:
            prefix = ""
            if calc:
                prefix = f"**Computation**\n\n`{calc.text}`\n\n"
            return prefix + rag.text, rag.model, rag.provider, rag.usage

        # Pure general chat.
        if general and not calc:
            return general.text, general.model, general.provider, general.usage

        # Calc only: ask the LLM to explain the result using the value as fact.
        if calc and not general:
            return f"**Computation**\n\n`{calc.text}`", None, None, {}

        # Both calc and general: give the LLM the computed result as ground truth.
        if calc and general:
            # Re-run general chat with the calculator result in the prompt.
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
