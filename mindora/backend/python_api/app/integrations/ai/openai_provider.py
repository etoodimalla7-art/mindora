"""OpenAI chat provider (optional).

Thin REST wrapper — keeps the app free of the openai SDK until Phase 9.
"""
from __future__ import annotations

from typing import Any

import httpx

from app.core.config import settings
from app.core.errors import AppError
from app.core.logging import get_logger
from app.integrations.ai.provider import ChatMessage, ChatResponse

logger = get_logger(__name__)


class OpenAIChatProvider:
    name = "openai"
    default_model = "gpt-4o-mini"

    def __init__(self, api_key: str | None = None, base_url: str | None = None) -> None:
        self._api_key = api_key or settings.OPENAI_API_KEY
        self._base_url = (base_url or settings.OPENAI_BASE_URL).rstrip("/")

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

        payload: dict[str, Any] = {
            "model": model,
            "messages": [{"role": m.role, "content": m.content} for m in messages],
            "temperature": temperature,
        }
        if max_tokens:
            payload["max_tokens"] = max_tokens
        if json_mode:
            payload["response_format"] = {"type": "json_object"}

        headers = {"Authorization": f"Bearer {key}"}
        async with httpx.AsyncClient(timeout=settings.AI_REQUEST_TIMEOUT_SECONDS) as client:
            r = await client.post(f"{self._base_url}/chat/completions", json=payload, headers=headers)
            if r.status_code >= 400:
                logger.error("openai_chat_failed", status=r.status_code, body=r.text[:500])
                raise AppError(
                    "The AI service is temporarily unavailable.",
                    code="ai_unavailable",
                    status_code=502,
                )
            data = r.json()

        content = data["choices"][0]["message"]["content"]
        return ChatResponse(
            content=content,
            model=model,
            provider=self.name,
            finish_reason=data["choices"][0].get("finish_reason"),
            usage=data.get("usage", {}),
            raw=data,
        )
