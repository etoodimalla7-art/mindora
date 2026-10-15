"""Notification service package.

Exposes:
- templates: rendering engine for notification title/body (FR + EN)
- (upcoming 12B.2) rules: business rules for when to send what
- (upcoming 12B.3) engine: orchestrator that persists + dispatches via provider
- (upcoming 12B.4) scheduler: APScheduler-based recurring jobs
"""

from app.services.notification.templates import (
    DEFAULT_LOCALE,
    TEMPLATES,
    Locale,
    NotificationContent,
    render,
)

__all__ = [
    "DEFAULT_LOCALE",
    "TEMPLATES",
    "Locale",
    "NotificationContent",
    "render",
]
