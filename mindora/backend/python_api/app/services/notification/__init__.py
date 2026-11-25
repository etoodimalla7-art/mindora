"""Notification service package.

Exposes:
- templates : rendering engine (FR/EN interpolation)
- rules     : business rules for when to send what
- engine    : orchestrator (dedup → render → persist → dispatch)
- scheduler : APScheduler-based recurring jobs
- jobs      : job functions (called by scheduler)
- hooks     : realtime hooks (called by business services)
"""

from app.services.notification.engine import NotificationEngine
from app.services.notification.hooks import (
    on_document_ready,
    on_mock_exam_generated,
    on_session_completed,
)
from app.services.notification.rules import (
    ALL_RULES,
    NotificationIntent,
    evaluate_rules,
    rule_exam_countdown,
    rule_inactivity,
    rule_session_reminder,
    rule_streak,
    rule_subscription_expiring,
)
from app.services.notification.templates import (
    DEFAULT_LOCALE,
    TEMPLATES,
    Locale,
    NotificationContent,
    get_template_raw,
    list_templates,
    render,
)

__all__ = [
    # engine
    "NotificationEngine",
    # templates
    "DEFAULT_LOCALE",
    "TEMPLATES",
    "Locale",
    "NotificationContent",
    "render",
    "list_templates",
    "get_template_raw",
    # rules
    "ALL_RULES",
    "NotificationIntent",
    "evaluate_rules",
    "rule_session_reminder",
    "rule_streak",
    "rule_exam_countdown",
    "rule_inactivity",
    "rule_subscription_expiring",
    # hooks
    "on_session_completed",
    "on_document_ready",
    "on_mock_exam_generated",
]
