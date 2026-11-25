"""Anthropic Claude provider (optional)."""
from __future__ import annotations

from typing import Any

import httpx

from app.core.config import settings
from app.core.errors import AppError
from app.core.logging import get_logger
from app.integrations.ai.provider import ChatMessage, ChatResponse

logger = get_logger(__name__)


class AnthropicChatProvider:
    name = "anthropic"
    default_model = "claude-3-5-sonnet-latest"

    def __init__(self, api_key: str | None = None, base_url: str | None = None) -> None:
        self._api_key = api_key or settings.ANTHROPIC_API_KEY
        self._base_url = (base_url or settings.ANTHROPIC_BASE_URL).rstrip("/")

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

        system_msgs = [m.content for m in messages if m.role == "system"]
        convo = [{"role": m.role, "content": m.content} for m in messages if m.role != "system"]

        payload: dict[str, Any] = {
            "model": model,
            "messages": convo,
            "max_tokens": max_tokens or 2048,
            "temperature": temperature,
        }
        if system_msgs:
            payload["system"] = "\n\n".join(system_msgs)

        headers = {
            "x-api-key": key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }
        async with httpx.AsyncClient(timeout=settings.AI_REQUEST_TIMEOUT_SECONDS) as client:
            r = await client.post(f"{self._base_url}/v1/messages", json=payload, headers=headers)
            if r.status_code >= 400:
                logger.error("anthropic_chat_failed", status=r.status_code, body=r.text[:500])
                raise AppError(
                    "The AI service is temporarily unavailable.",
                    code="ai_unavailable",
                    status_code=502,
                )
            data = r.json()

        parts = data.get("content", [])
        text = "".join(p.get("text", "") for p in parts if p.get("type") == "text")

        return ChatResponse(
            content=text,
            model=model,
            provider=self.name,
            finish_reason=data.get("stop_reason"),
            usage=data.get("usage", {}),
            raw=data,
        )
