"""Tool protocol used by the orchestrator."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol

from app.integrations.ai.provider import ChatMessage


@dataclass
class ToolContext:
    """Everything a tool may need to execute."""

    user_id: str
    message: str
    history: list[ChatMessage] = field(default_factory=list)
    subject: str | None = None
    # Tool-specific extras (e.g. document ids for course_rag).
    extras: dict[str, Any] = field(default_factory=dict)


@dataclass
class ToolResult:
    """A tool returns text plus optional structured metadata."""

    text: str
    tool_name: str
    model: str | None = None
    provider: str | None = None
    usage: dict[str, int] = field(default_factory=dict)
    error: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


class Tool(Protocol):
    """Every tool exposes a name, a description, and an async execute()."""

    name: str
    description: str

    async def execute(self, ctx: ToolContext) -> ToolResult: ...
