"""Async event bus for real-time admin notifications.

Simplified implementation: subscribers are async callables that receive
events directly (no intermediate queue → no cross-loop deadlock).

Usage:
    await event_bus.publish("user.created", {"user_id": "...", ...})
"""
from __future__ import annotations

import asyncio
import logging
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Awaitable, Callable

logger = logging.getLogger(__name__)


# Event type → required permission to receive
EVENT_PERMISSIONS: dict[str, str | None] = {
    "user.created": "users.read",
    "user.updated": "users.read",
    "user.suspended": "users.read",
    "user.deleted": "users.read",
    "document.submitted": "documents.read",
    "document.approved": "documents.read",
    "document.rejected": "documents.read",
    "document.updated": "documents.read",
    "document.deleted": "documents.read",
    "moderation.created": "moderation.manage",
    "paper.created": "documents.read",
    "paper.updated": "documents.read",
    "paper.deleted": "documents.read",
    "ai.request.completed": "ai.read",
    "ai.request.failed": "ai.read",
    "system.error": "system.manage",
    "system.status.changed": "system.manage",
    "notification.created": "notifications.manage",
}


EventHandler = Callable[[dict[str, Any]], Awaitable[None]]


@dataclass
class Subscriber:
    """A subscriber is an async callable + its permission set."""
    id: uuid.UUID
    handler: EventHandler
    permissions: set[str] = field(default_factory=set)

    def can_receive(self, event_type: str) -> bool:
        required = EVENT_PERMISSIONS.get(event_type)
        if required is None:
            return False
        return required in self.permissions


class EventBus:
    """Simple in-memory event bus (single uvicorn worker).

    Subscribers are awaited directly (no queue) → no cross-loop deadlock.
    For multi-worker scale, replace with Redis pub/sub.
    """

    def __init__(self) -> None:
        self._subscribers: dict[uuid.UUID, Subscriber] = {}

    def subscribe(
        self, handler: EventHandler, permissions: set[str]
    ) -> Subscriber:
        sub_id = uuid.uuid4()
        sub = Subscriber(id=sub_id, handler=handler, permissions=permissions)
        self._subscribers[sub_id] = sub
        logger.info(
            "event_bus_subscribe id=%s perms=%d count=%d",
            sub_id, len(permissions), len(self._subscribers),
        )
        return sub

    def unsubscribe(self, sub_id: uuid.UUID) -> None:
        self._subscribers.pop(sub_id, None)
        logger.info("event_bus_unsubscribe id=%s", sub_id)

    async def publish(
        self, event_type: str, payload: dict[str, Any]
    ) -> int:
        if event_type not in EVENT_PERMISSIONS:
            logger.warning("event_bus_unknown_event type=%s", event_type)
            return 0

        message = {
            "type": event_type,
            "payload": payload,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        delivered = 0
        dead: list[uuid.UUID] = []
        for sub in list(self._subscribers.values()):
            if not sub.can_receive(event_type):
                continue
            try:
                await sub.handler(message)
                delivered += 1
            except Exception as exc:  # noqa: BLE001
                logger.warning(
                    "event_bus_deliver_failed sub=%s error=%s", sub.id, exc
                )
                dead.append(sub.id)

        for sub_id in dead:
            self.unsubscribe(sub_id)

        logger.info(
            "event_bus_publish type=%s delivered=%d", event_type, delivered
        )
        return delivered

    def subscriber_count(self) -> int:
        return len(self._subscribers)


event_bus = EventBus()
