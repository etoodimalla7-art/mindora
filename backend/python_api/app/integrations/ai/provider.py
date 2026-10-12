"""Provider interfaces for chat and embedding models.

Every concrete provider (Gemini, OpenAI, Anthropic, ...) implements these
interfaces. The rest of the application never imports provider SDKs directly.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Literal, Protocol

Role = Literal["system", "user", "assistant", "tool"]


@dataclass(slots=True)
class ChatMessage:
    role: Role
    content: str
    name: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class ChatResponse:
    content: str
    model: str
    provider: str
    finish_reason: str | None = None
    usage: dict[str, int] = field(default_factory=dict)
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class EmbeddingResponse:
    vectors: list[list[float]]
    model: str
    provider: str
    dimensions: int
    usage: dict[str, int] = field(default_factory=dict)


class ChatProvider(Protocol):
    name: str
    default_model: str

    async def chat(
        self,
        messages: list[ChatMessage],
        *,
        model: str | None = None,
        temperature: float = 0.4,
        max_tokens: int | None = None,
        json_mode: bool = False,
        extra: dict[str, Any] | None = None,
    ) -> ChatResponse: ...


class EmbeddingProvider(Protocol):
    name: str
    default_model: str

    async def embed(
        self,
        texts: list[str],
        *,
        model: str | None = None,
    ) -> EmbeddingResponse: ...
