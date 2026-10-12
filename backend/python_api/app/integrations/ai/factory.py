"""Provider factory — the only place that knows about concrete providers."""
from __future__ import annotations

from functools import lru_cache

from app.core.config import settings
from app.core.errors import AppError
from app.integrations.ai.anthropic_provider import AnthropicChatProvider
from app.integrations.ai.gemini import GeminiChatProvider, GeminiEmbeddingProvider
from app.integrations.ai.openai_provider import OpenAIChatProvider
from app.integrations.ai.provider import ChatProvider, EmbeddingProvider


@lru_cache(maxsize=4)
def get_chat_provider(name: str | None = None) -> ChatProvider:
    provider = (name or settings.AI_DEFAULT_PROVIDER).lower()
    if provider == "gemini":
        return GeminiChatProvider()
    if provider == "openai":
        return OpenAIChatProvider()
    if provider == "anthropic":
        return AnthropicChatProvider()
    raise AppError(
        f"Unknown AI provider: {provider}",
        code="ai_provider_unknown",
        status_code=500,
    )


@lru_cache(maxsize=4)
def get_embedding_provider(name: str | None = None) -> EmbeddingProvider:
    provider = (name or settings.AI_EMBEDDING_PROVIDER).lower()
    if provider == "gemini":
        return GeminiEmbeddingProvider()
    raise AppError(
        f"Unknown embedding provider: {provider}",
        code="ai_provider_unknown",
        status_code=500,
    )
