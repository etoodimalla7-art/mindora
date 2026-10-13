"""General conversation tool — free-form answers without external context."""
from __future__ import annotations

from app.integrations.ai.factory import get_chat_provider
from app.integrations.ai.provider import ChatMessage
from ai.tools.base import ToolContext, ToolResult

_SYSTEM = """You are MINDORA, a patient academic tutor for students in Cameroon.
You answer questions clearly, in the same language as the student.
You show your reasoning step by step for math and science.
You never invent citations. If you are not sure about a fact, say so.
You keep answers structured: short intro, main explanation, brief recap.
Never mention that you are an AI language model. Just teach."""


class GeneralChatTool:
    name = "general_chat"
    description = (
        "Answer general academic questions using the language model's own "
        "knowledge. Use for explanations, definitions, worked examples, "
        "clarifications that do not require looking up the student's files."
    )

    async def execute(self, ctx: ToolContext) -> ToolResult:
        provider = get_chat_provider()
        messages: list[ChatMessage] = [ChatMessage(role="system", content=_SYSTEM)]
        # Pass a trimmed history so the model has continuity.
        for m in ctx.history[-12:]:
            messages.append(m)
        messages.append(ChatMessage(role="user", content=ctx.message))

        try:
            response = await provider.chat(
                messages,
                temperature=0.5,
                max_tokens=1200,
            )
            return ToolResult(
                text=response.content,
                tool_name=self.name,
                model=response.model,
                provider=response.provider,
                usage=response.usage or {},
            )
        except Exception as exc:  # noqa: BLE001
            return ToolResult(
                text="I could not generate a response right now. Please try again.",
                tool_name=self.name,
                error=str(exc),
            )
