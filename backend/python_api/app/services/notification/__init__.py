"""Notification service package.

Exposes:
- templates: rendering engine for notification title/body (FR + EN)
- rules: business rules for when to send what (12B.2)
- (upcoming 12B.3) engine: orchestrator that persists + dispatches via provider
- (upcoming 12B.4) scheduler: APScheduler-based recurring jobs
"""

from app.services.notification.rules import (
    ALL_RULES,
    NotificationIntent,
    evaluate_rules,
    rule_exam_countdown,
    rule_plan_nudge,
    rule_streak_alert,
    rule_study_reminder,
    rule_subscription_expiring,
)
from app.services.notification.templates import (
    DEFAULT_LOCALE,
    TEMPLATES,
    Locale,
    NotificationContent,
    render,
)

__all__ = [
    # templates
    "DEFAULT_LOCALE",
    "TEMPLATES",
    "Locale",
    "NotificationContent",
    "render",
    # rules
    "ALL_RULES",
    "NotificationIntent",
    "evaluate_rules",
    "rule_study_reminder",
    "rule_streak_alert",
    "rule_exam_countdown",
    "rule_plan_nudge",
    "rule_subscription_expiring",
]