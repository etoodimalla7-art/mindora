"""Notification provider interface — implemented by FCM, OneSignal, etc."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol


@dataclass(slots=True)
class PushMessage:
    """A push notification payload."""

    token: str                      # FCM device token
    title: str
    body: str
    deep_link: str | None = None    # Custom data for navigation
    data: dict[str, Any] = field(default_factory=dict)
    image_url: str | None = None
    # Priority: "normal" | "high"
    priority: str = "high"


@dataclass(slots=True)
class PushResult:
    """Result of sending a push."""

    success: bool
    message_id: str | None = None
    error: str | None = None
    raw: dict[str, Any] = field(default_factory=dict)


class NotificationProvider(Protocol):
    name: str

    async def send(self, message: PushMessage) -> PushResult: ...

    async def send_batch(self, messages: list[PushMessage]) -> list[PushResult]: ...
