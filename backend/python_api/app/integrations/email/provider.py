"""Email provider interface."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(slots=True)
class EmailMessage:
    to: str
    subject: str
    html: str
    text: str | None = None


@dataclass(slots=True)
class EmailResult:
    success: bool
    message_id: str | None = None
    error: str | None = None


class EmailProvider(Protocol):
    name: str

    async def send(self, message: EmailMessage) -> EmailResult: ...
