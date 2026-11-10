"""Google Gemini provider using the official google-genai SDK.

Handles both legacy (AIza*) and new-style (AQ.*) API keys.
Supports chat, chat_stream (SSE), embeddings, and inline images (Phase 11C).
"""
from __future__ import annotations

import asyncio
import base64
import logging
from collections.abc import AsyncIterator
from typing import Any

from google import genai
from google.genai import types as genai_types

from app.core.config import settings
from app.core.errors import AppError
from app.integrations.ai.provider import (
    ChatMessage,
    ChatResponse,
    EmbeddingResponse,
)

logger = logging.getLogger(__name__)

EMBEDDING_DIMENSIONS = 768

_ALLOWED_IMAGE_MIMES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
_MAX_IMAGE_BYTES = 5 * 1024 * 1024


def _to_gemini_role(role: str) -> str:
    return {"assistant": "model", "system": "user"}.get(role, role)


def _build_parts(message: ChatMessage) -> list[genai_types.Part]:
    parts: list[genai_types.Part] = [genai_types.Part(text=message.content or "")]
    if message.image_base64:
        mime = (message.image_mime_type or "image/jpeg").lower()
        if mime not in _ALLOWED_IMAGE_MIMES:
            logger.warning("gemini_inline_image_bad_mime mime=%s", mime)
            return parts
        try:
            raw_b64 = message.image_base64
            if raw_b64.startswith("data:"):
                raw_b64 = raw_b64.split(",", 1)[1] if "," in raw_b64 else ""
            data = base64.b64decode(raw_b64, validate=True)
            if not data:
                return parts
            if len(data) > _MAX_IMAGE_BYTES:
                logger.warning("gemini_inline_image_too_large size=%d", len(data))
                return parts
            parts.append(genai_types.Part.from_bytes(data=data, mime_type=mime))
        except Exception as exc:  # noqa: BLE001
            logger.warning("gemini_inline_image_decode_failed error=%s", exc)
    return parts


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

        system_chunks = [m.content for m in messages if m.role == "system"]
        system_instruction = "\n\n".join(system_chunks) if system_chunks else None

        contents = [
            genai_types.Content(
                role=_to_gemini_role(m.role),
                parts=_build_parts(m),
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

        last_error: Exception | None = None
        response: Any = None
        for attempt in range(3):
            try:
                response = await client.aio.models.generate_content(
                    model=model_name,
                    contents=contents,
                    config=config,
                )
                break
            except Exception as exc:  # noqa: BLE001
                last_error = exc
                msg = str(exc)
                transient = (
                    "503" in msg
                    or "429" in msg
                    or "UNAVAILABLE" in msg
                    or "RESOURCE_EXHAUSTED" in msg
                )
                if transient and attempt < 2:
                    logger.warning(
                        "gemini_chat_retry attempt=%d error=%s",
                        attempt + 1,
                        msg[:120],
                    )
                    await asyncio.sleep(2 ** attempt)
                    continue
                logger.error("gemini_chat_failed error=%s", msg[:200])
                raise AppError(
                    "The AI service is temporarily unavailable.",
                    code="ai_unavailable",
                    status_code=502,
                ) from exc
        else:
            logger.error("gemini_chat_exhausted error=%s", str(last_error)[:200])
            raise AppError(
                "The AI service is temporarily unavailable.",
                code="ai_unavailable",
                status_code=502,
            ) from last_error

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

    async def chat_stream(
        self,
        messages: list[ChatMessage],
        *,
        model: str | None = None,
        temperature: float = 0.4,
        max_tokens: int | None = None,
    ) -> AsyncIterator[str]:
        client = self._require_client()
        model_name = model or self.default_model

        system_chunks = [m.content for m in messages if m.role == "system"]
        system_instruction = "\n\n".join(system_chunks) if system_chunks else None

        contents = [
            genai_types.Content(
                role=_to_gemini_role(m.role),
                parts=_build_parts(m),
            )
            for m in messages
            if m.role != "system"
        ]

        config = genai_types.GenerateContentConfig(
            temperature=temperature,
            max_output_tokens=max_tokens or 1200,
            system_instruction=system_instruction,
        )

        last_error: Exception | None = None
        for attempt in range(3):
            try:
                stream = await client.aio.models.generate_content_stream(
                    model=model_name,
                    contents=contents,
                    config=config,
                )
                async for chunk in stream:
                    text = self._chunk_text(chunk)
                    if text:
                        yield text
                return
            except Exception as exc:  # noqa: BLE001
                last_error = exc
                msg = str(exc)
                transient = (
                    "503" in msg
                    or "429" in msg
                    or "UNAVAILABLE" in msg
                )
                if transient and attempt < 2:
                    logger.warning(
                        "gemini_stream_retry attempt=%d error=%s",
                        attempt + 1,
                        msg[:120],
                    )
                    await asyncio.sleep(2 ** attempt)
                    continue
                logger.error("gemini_stream_failed error=%s", msg[:200])
                raise AppError(
                    "The AI service is temporarily unavailable.",
                    code="ai_unavailable",
                    status_code=502,
                ) from exc
        raise AppError(
            "The AI service is temporarily unavailable.",
            code="ai_unavailable",
            status_code=502,
        ) from last_error

    @staticmethod
    def _chunk_text(chunk: Any) -> str:
        try:
            text = getattr(chunk, "text", None)
            if text:
                return text
        except Exception:  # noqa: BLE001
            pass
        try:
            candidates = getattr(chunk, "candidates", None) or []
            if not candidates:
                return ""
            content = getattr(candidates[0], "content", None)
            if not content:
                return ""
            parts = getattr(content, "parts", None) or []
            collected: list[str] = []
            for p in parts:
                t = getattr(p, "text", None)
                if t:
                    collected.append(t)
            return "".join(collected)
        except Exception:  # noqa: BLE001
            return ""

    @staticmethod
    def _extract_text(response: Any) -> str:
        try:
            text = response.text
            if text:
                return text
        except Exception:  # noqa: BLE001
            pass
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

        config = genai_types.EmbedContentConfig(
            output_dimensionality=EMBEDDING_DIMENSIONS,
        )

        try:
            response = await client.aio.models.embed_content(
                model=model_name,
                contents=texts,
                config=config,
            )
        except Exception as exc:  # noqa: BLE001
            logger.error("gemini_embed_failed error=%s", str(exc)[:200])
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
