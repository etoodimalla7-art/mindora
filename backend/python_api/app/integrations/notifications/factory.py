"""Notification provider factory."""
from __future__ import annotations

from functools import lru_cache

from app.core.config import settings
from app.core.errors import AppError
from app.integrations.notifications.fcm import FCMProvider
from app.integrations.notifications.provider import NotificationProvider


@lru_cache(maxsize=2)
def get_notification_provider() -> NotificationProvider:
    provider_name = settings.NOTIFICATION_PROVIDER.lower()
    if provider_name == "fcm":
        return FCMProvider()
    if provider_name == "none":
        raise AppError(
            "Notifications are not enabled on this server.",
            code="notifications_disabled",
            status_code=503,
        )
    raise AppError(
        f"Unknown notification provider: {provider_name}",
        code="notifications_provider_unknown",
        status_code=500,
    )
