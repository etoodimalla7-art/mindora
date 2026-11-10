"""AI chat schemas."""
from __future__ import annotations

import base64
import uuid
from datetime import datetime

from pydantic import BaseModel, Field, model_validator

_ALLOWED_IMAGE_MIMES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
_MAX_IMAGE_BYTES = 5 * 1024 * 1024


class ChatRequest(BaseModel):
    message: str = Field(default="", max_length=8000)
    image_base64: str | None = None
    image_mime_type: str | None = None
    audio_base64: str | None = None
    conversation_id: uuid.UUID | None = None
    subject: str | None = Field(default=None, max_length=80)

    context_type: str | None = Field(default=None, max_length=40)
    context_id: uuid.UUID | None = None

    @model_validator(mode="after")
    def _validate_multimodal(self) -> "ChatRequest":
        has_text = bool((self.message or "").strip())
        has_image = bool(self.image_base64)

        if not has_text and not has_image:
            raise ValueError("Either 'message' or 'image_base64' is required.")

        if has_image:
            mime = (self.image_mime_type or "image/jpeg").lower()
            if mime not in _ALLOWED_IMAGE_MIMES:
                raise ValueError(
                    f"Unsupported image_mime_type '{mime}'. "
                    f"Allowed: {sorted(_ALLOWED_IMAGE_MIMES)}"
                )
            raw = self.image_base64
            if raw.startswith("data:"):
                raw = raw.split(",", 1)[1] if "," in raw else ""
                self.image_base64 = raw
            try:
                decoded = base64.b64decode(raw, validate=True)
            except Exception as exc:  # noqa: BLE001
                raise ValueError("image_base64 is not valid base64.") from exc
            if not decoded:
                raise ValueError("image_base64 decodes to empty data.")
            if len(decoded) > _MAX_IMAGE_BYTES:
                raise ValueError(
                    f"Image too large ({len(decoded)} bytes). "
                    f"Max is {_MAX_IMAGE_BYTES} bytes (5 MB)."
                )
            self.image_mime_type = mime
            if not has_text:
                self.message = (
                    "Décris cette image et, si c'est un exercice, "
                    "résous-le étape par étape."
                )

        return self


class ToolUsage(BaseModel):
    name: str
    args: dict | None = None
    result_preview: str | None = None


class MessageOut(BaseModel):
    id: uuid.UUID
    role: str
    content: str
    tools_used: list[dict] = Field(default_factory=list)
    model: str | None = None
    provider: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True


class ConversationOut(BaseModel):
    id: uuid.UUID
    title: str
    subject: str | None = None
    message_count: int
    is_archived: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ConversationDetail(ConversationOut):
    messages: list[MessageOut] = Field(default_factory=list)


class ChatResponse(BaseModel):
    conversation_id: uuid.UUID
    message: MessageOut
    usage: dict = Field(default_factory=dict)


class IntentDecision(BaseModel):
    intent: str
    confidence: float = Field(ge=0.0, le=1.0)
    tools: list[str] = Field(default_factory=list)
    reasoning: str | None = None
