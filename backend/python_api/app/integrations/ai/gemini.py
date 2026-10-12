"""Google Gemini provider (default).

Phase 1 implementation is a thin HTTP wrapper using the REST API. Streaming
and function-calling support are added in Phase 9.
"""
from __future__ import annotations

from typing import Any

import httpx

from app.core.config import settings
from app.core.errors import AppError
from app.core.logging import get_logger
from app.integrations.ai.provider import (
    ChatMessage,
    ChatResponse,
    EmbeddingResponse,
)

logger = get_logger(__name__)


def _to_gemini_role(role: str) -> str:
    return {"assistant": "model", "system": "user"}.get(role, role)


class GeminiChatProvider:
    name = "gemini"
    default_model = settings.AI_DEFAULT_MODEL

    def __init__(self, api_key: str | None = None, base_url: str | None = None) -> None:
        self._api_key = api_key or settings.GEMINI_API_KEY
        self._base_url = (base_url or settings.GEMINI_BASE_URL).rstrip("/")

    def _require_key(self) -> str:
        if not self._api_key:
            raise AppError(
                "AI provider is not configured.",
                code="ai_unconfigured",
                status_code=503,
            )
        return self._api_key

    async def chat(
        self,
        messages: list[ChatMessage],
        *,
        model: str | None = None,
        temperature: float = 0.4,
        max_tokens: int | None = None,
        json_mode: bool = False,
        extra: dict[str, Any] | None = None,
    ) -> ChatResponse:
        key = self._require_key()
        model = model or self.default_model

        contents = [
            {"role": _to_gemini_role(m.role), "parts": [{"text": m.content}]} for m in messages
        ]

        generation_config: dict[str, Any] = {"temperature": temperature}
        if max_tokens:
            generation_config["maxOutputTokens"] = max_tokens
        if json_mode:
            generation_config["responseMimeType"] = "application/json"

        url = f"{self._base_url}/v1beta/models/{model}:generateContent"
        payload = {"contents": contents, "generationConfig": generation_config}

        async with httpx.AsyncClient(timeout=settings.AI_REQUEST_TIMEOUT_SECONDS) as client:
            r = await client.post(url, params={"key": key}, json=payload)
            if r.status_code >= 400:
                logger.error("gemini_chat_failed", status=r.status_code, body=r.text[:500])
                raise AppError(
                    "The AI service is temporarily unavailable.",
                    code="ai_unavailable",
                    status_code=502,
                )
            data = r.json()

        try:
            content = data["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError) as exc:
            raise AppError(
                "The AI returned an unexpected response.",
                code="ai_bad_response",
                status_code=502,
            ) from exc

        return ChatResponse(
            content=content,
            model=model,
            provider=self.name,
            finish_reason=data.get("candidates", [{}])[0].get("finishReason"),
            usage=data.get("usageMetadata", {}),
            raw=data,
        )


class GeminiEmbeddingProvider:
    name = "gemini"
    default_model = settings.AI_EMBEDDING_MODEL

    def __init__(self, api_key: str | None = None, base_url: str | None = None) -> None:
        self._api_key = api_key or settings.GEMINI_API_KEY
        self._base_url = (base_url or settings.GEMINI_BASE_URL).rstrip("/")

    def _require_key(self) -> str:
        if not self._api_key:
            raise AppError(
                "AI provider is not configured.",
                code="ai_unconfigured",
                status_code=503,
            )
        return self._api_key

    async def embed(
        self,
        texts: list[str],
        *,
        model: str | None = None,
    ) -> EmbeddingResponse:
        key = self._require_key()
        model = model or self.default_model
        vectors: list[list[float]] = []

        async with httpx.AsyncClient(timeout=settings.AI_REQUEST_TIMEOUT_SECONDS) as client:
            for text in texts:
                url = f"{self._base_url}/v1beta/models/{model}:embedContent"
                payload = {"content": {"parts": [{"text": text}]}}
                r = await client.post(url, params={"key": key}, json=payload)
                if r.status_code >= 400:
                    logger.error("gemini_embed_failed", status=r.status_code, body=r.text[:500])
                    raise AppError(
                        "The AI service is temporarily unavailable.",
                        code="ai_unavailable",
                        status_code=502,
                    )
                data = r.json()
                vector = data.get("embedding", {}).get("values")
                if not vector:
                    raise AppError(
                        "The AI returned an unexpected response.",
                        code="ai_bad_response",
                        status_code=502,
                    )
                vectors.append(vector)

        dims = len(vectors[0]) if vectors else 0
        return EmbeddingResponse(
            vectors=vectors,
            model=model,
            provider=self.name,
            dimensions=dims,
        )
