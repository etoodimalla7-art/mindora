"""AI Orchestrator — routes each user message to the right tools."""
from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass

from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage
from ai.tools import CalculatorTool, GeneralChatTool, Tool, ToolContext, ToolResult

logger = logging.getLogger(__name__)


@dataclass
class OrchestratorResult:
    text: str
    tools_used: list[dict]
    model: str | None = None
    provider: str | None = None
    usage: dict = None  # type: ignore[assignment]
    reasoning: str | None = None


_CLASSIFIER_SYSTEM = """You are a routing assistant.
Given a student message, decide which tools are needed to answer well.
Available tools:
  - general_chat : explanation, definition, reasoning, teaching
  - calculator   : plain arithmetic evaluation only

Reply strictly with a JSON object:
{"intent": "<short label>", "confidence": <0..1>, "tools": ["general_chat"], "reasoning": "<short>"}

Rules:
- ALWAYS include general_chat, unless the message is a pure calculation.
- If the message asks for math reasoning (derivatives, integrals, proofs),
  use general_chat only — the model handles symbolic reasoning itself.
- If the message is a bare arithmetic expression like "2+3*4" or "sqrt(9)",
  include calculator AND general_chat.
- Keep tool list short. Never include a tool that is not in the list.
"""


class Orchestrator:
    """Classify → execute → compose."""

    def __init__(self) -> None:
        self.tools: dict[str, Tool] = {
            "general_chat": GeneralChatTool(),
            "calculator": CalculatorTool(),
        }

    async def run(self, ctx: ToolContext) -> OrchestratorResult:
        # 1. Classify intent.
        decision = await self._classify(ctx.message)
        selected = [t for t in decision.get("tools", []) if t in self.tools]
        if not selected:
            selected = ["general_chat"]

        # 2. Run each tool, collect results.
        results: list[ToolResult] = []
        for name in selected:
            tool = self.tools[name]
            try:
                r = await tool.execute(ctx)
                results.append(r)
            except Exception as exc:  # noqa: BLE001
                logger.exception("tool_execution_failed name=%s", name)
                results.append(ToolResult(text="", tool_name=name, error=str(exc)))

        # 3. Compose the final answer.
        #    - If general_chat succeeded, use its output as the base.
        #    - If calculator succeeded, prepend its result as context.
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

    # ---------- Intent classification ----------

    async def _classify(self, message: str) -> dict:
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

        # Fallback: heuristic.
        tools = ["general_chat"]
        if _looks_like_arithmetic(message):
            tools.insert(0, "calculator")
        return {"intent": "general", "confidence": 0.5, "tools": tools, "reasoning": "heuristic"}

    # ---------- Response composition ----------

    async def _compose(
        self,
        ctx: ToolContext,
        results: list[ToolResult],
    ) -> tuple[str, str | None, str | None, dict]:
        # Pick general_chat's output as the main body.
        main = next(
            (r for r in results if r.tool_name == "general_chat" and r.text),
            None,
        )
        calc = next(
            (r for r in results if r.tool_name == "calculator" and r.text),
            None,
        )

        if main and calc:
            composed = f"**Computation**\n\n`{calc.text}`\n\n**Explanation**\n\n{main.text}"
            return composed, main.model, main.provider, main.usage

        if main:
            return main.text, main.model, main.provider, main.usage

        if calc:
            return f"**Computation**\n\n`{calc.text}`", calc.model, calc.provider, calc.usage

        # Nothing succeeded → apologize.
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
