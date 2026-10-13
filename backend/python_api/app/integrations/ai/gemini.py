"""Google Gemini provider using the official google-genai SDK.

Supports both new-style (AQ.*) and legacy (AIza*) API keys.
"""
from __future__ import annotations

import asyncio
from typing import Any

from google import genai
from google.genai import types as genai_types

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
    """Map our generic roles to Gemini's roles.

    Gemini understands 'user' and 'model'. System prompts are handled
    separately by the SDK (system_instruction parameter).
    """
    return {"assistant": "model", "system": "user"}.get(role, role)


class GeminiChatProvider:
    name = "gemini"
    default_model = settings.AI_DEFAULT_MODEL

    def __init__(self, api_key: str | None = None) -> None:
        self._api_key = api_key or settings.GEMINI_API_KEY
        self._client: genai.Client | None = None

    def _require_client(self) -> genai.Client:
        if not self._api_key:
            raise AppError(
                "AI provider is not configured.",
                code="ai_unconfigured",
                status_code=503,
            )
        if self._client is None:
            try:
                self._client = genai.Client(api_key=self._api_key)
            except Exception as exc:  # noqa: BLE001
                logger.error("gemini_client_init_failed error=%s", exc)
                raise AppError(
                    "The AI service is not available.",
                    code="ai_unavailable",
                    status_code=502,
                ) from exc
        return self._client

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
        client = self._require_client()
        model_name = model or self.default_model

        # Split system prompt from the conversation.
        system_chunks = [m.content for m in messages if m.role == "system"]
        system_instruction = "\n\n".join(system_chunks) if system_chunks else None

        contents = [
            genai_types.Content(
                role=_to_gemini_role(m.role),
                parts=[genai_types.Part(text=m.content)],
            )
            for m in messages
            if m.role != "system"
        ]

        config = genai_types.GenerateContentConfig(
            temperature=temperature,
            max_output_tokens=max_tokens or 1200,
            system_instruction=system_instruction,
        )
        if json_mode:
            config.response_mime_type = "application/json"

        try:
            # The SDK exposes sync and async clients. We use the async
            # variant via .aio.
            response = await client.aio.models.generate_content(
                model=model_name,
                contents=contents,
                config=config,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error("gemini_chat_failed error=%s", exc)
            raise AppError(
                "The AI service is temporarily unavailable.",
                code="ai_unavailable",
                status_code=502,
            ) from exc

        text = self._extract_text(response)
        usage = self._extract_usage(response)

        return ChatResponse(
            content=text,
            model=model_name,
            provider=self.name,
            finish_reason=None,
            usage=usage,
            raw={},
        )

    # ---------- Helpers ----------

    @staticmethod
    def _extract_text(response: Any) -> str:
        # google-genai exposes response.text in most cases.
        try:
            text = response.text
            if text:
                return text
        except Exception:  # noqa: BLE001
            pass
        # Fallback: walk candidates/parts manually.
        try:
            parts = response.candidates[0].content.parts
            return "".join(getattr(p, "text", "") or "" for p in parts)
        except Exception:  # noqa: BLE001
            return ""

    @staticmethod
    def _extract_usage(response: Any) -> dict[str, int]:
        try:
            meta = response.usage_metadata
            return {
                "prompt_tokens": getattr(meta, "prompt_token_count", 0) or 0,
                "completion_tokens": getattr(meta, "candidates_token_count", 0) or 0,
                "total_tokens": getattr(meta, "total_token_count", 0) or 0,
            }
        except Exception:  # noqa: BLE001
            return {}


class GeminiEmbeddingProvider:
    name = "gemini"
    default_model = settings.AI_EMBEDDING_MODEL

    def __init__(self, api_key: str | None = None) -> None:
        self._api_key = api_key or settings.GEMINI_API_KEY
        self._client: genai.Client | None = None

    def _require_client(self) -> genai.Client:
        if not self._api_key:
            raise AppError(
                "AI provider is not configured.",
                code="ai_unconfigured",
                status_code=503,
            )
        if self._client is None:
            self._client = genai.Client(api_key=self._api_key)
        return self._client

    async def embed(
        self,
        texts: list[str],
        *,
        model: str | None = None,
    ) -> EmbeddingResponse:
        client = self._require_client()
        model_name = model or self.default_model

        try:
            response = await client.aio.models.embed_content(
                model=model_name,
                contents=texts,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error("gemini_embed_failed error=%s", exc)
            raise AppError(
                "The AI service is temporarily unavailable.",
                code="ai_unavailable",
                status_code=502,
            ) from exc

        vectors = [list(e.values) for e in response.embeddings]
        dims = len(vectors[0]) if vectors else 0
        return EmbeddingResponse(
            vectors=vectors,
            model=model_name,
            provider=self.name,
            dimensions=dims,
        )
