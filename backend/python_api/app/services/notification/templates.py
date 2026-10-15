"""Notification templates with FR/EN support and variable interpolation.

Template keys align with the NOTIF_TYPE_* constants in
app.models.notification.

Usage:
    content = render("session_reminder", "fr", {
        "user_name": "Alice",
        "subject_name": "Mathématiques",
        "minutes": 15,
    })
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from typing import Literal

logger = logging.getLogger(__name__)

Locale = Literal["fr", "en"]
DEFAULT_LOCALE: Locale = "fr"
SUPPORTED_LOCALES: tuple[Locale, ...] = ("fr", "en")


@dataclass(frozen=True)
class NotificationContent:
    """Rendered notification payload."""

    title: str
    body: str


# ---------------------------------------------------------------------------
# Templates registry — keys MUST match NOTIF_TYPE_* in models/notification.py
# ---------------------------------------------------------------------------

TEMPLATES: dict[str, dict[Locale, dict[str, str]]] = {
    # --- session_reminder (NOTIF_TYPE_SESSION_REMINDER) --------------------
    "session_reminder": {
        "fr": {
            "title": "📚 C'est l'heure, {{user_name}} !",
            "body": "Ta session {{subject_name}} commence dans {{minutes}} min.",
        },
        "en": {
            "title": "📚 Time to study, {{user_name}}!",
            "body": "Your {{subject_name}} session starts in {{minutes}} min.",
        },
    },
    # --- streak (NOTIF_TYPE_STREAK) ----------------------------------------
    "streak": {
        "fr": {
            "title": "🔥 Ne casse pas ta série de {{streak_days}} jours !",
            "body": "Une petite session de 10 min suffit pour garder ta série. On y va ?",
        },
        "en": {
            "title": "🔥 Don't break your {{streak_days}}-day streak!",
            "body": "A quick 10-min session keeps your streak alive. Let's go?",
        },
    },
    # --- exam_countdown (NOTIF_TYPE_EXAM_COUNTDOWN) ------------------------
    "exam_countdown": {
        "fr": {
            "title": "⏳ Plus que {{days_left}} jours avant ton examen",
            "body": "Concentre-toi sur {{subject_name}}. MINDORA peut générer un mock exam pour t'évaluer.",
        },
        "en": {
            "title": "⏳ Only {{days_left}} days until your exam",
            "body": "Focus on {{subject_name}}. MINDORA can generate a mock exam to assess you.",
        },
    },
    # --- inactivity (NOTIF_TYPE_INACTIVITY) --------------------------------
    "inactivity": {
        "fr": {
            "title": "👋 On reprend, {{user_name}} ?",
            "body": "Ton plan '{{plan_name}}' t'attend. 15 minutes aujourd'hui et tu gardes le rythme.",
        },
        "en": {
            "title": "👋 Shall we resume, {{user_name}}?",
            "body": "Your plan '{{plan_name}}' is waiting. 15 minutes today keeps the rhythm.",
        },
    },
    # --- session_completed (NOTIF_TYPE_SESSION_COMPLETED) ------------------
    "session_completed": {
        "fr": {
            "title": "✅ Session terminée, bravo !",
            "body": "Tu viens de compléter {{subject_name}}. Série actuelle : {{streak_days}} jours 🔥",
        },
        "en": {
            "title": "✅ Session complete, well done!",
            "body": "You just finished {{subject_name}}. Current streak: {{streak_days}} days 🔥",
        },
    },
    # --- document_ready (NOTIF_TYPE_DOCUMENT_READY) ------------------------
    "document_ready": {
        "fr": {
            "title": "📄 Ton document est prêt",
            "body": "'{{document_title}}' a été traité. Pose tes questions à l'AI tutor dès maintenant !",
        },
        "en": {
            "title": "📄 Your document is ready",
            "body": "'{{document_title}}' has been processed. Ask the AI tutor anything now!",
        },
    },
    # --- subscription_expiring (NOTIF_TYPE_SUBSCRIPTION_EXPIRING) ----------
    "subscription_expiring": {
        "fr": {
            "title": "💳 Ton abonnement expire dans {{days_until_expiry}} jours",
            "body": "Renouvelle maintenant pour garder l'accès illimité à l'AI tutor et aux mock exams.",
        },
        "en": {
            "title": "💳 Your subscription expires in {{days_until_expiry}} days",
            "body": "Renew now to keep unlimited access to the AI tutor and mock exams.",
        },
    },
    # --- milestone (NOTIF_TYPE_MILESTONE) — generic fallback ---------------
    "milestone": {
        "fr": {
            "title": "🏆 {{milestone_title}}",
            "body": "{{milestone_body}}",
        },
        "en": {
            "title": "🏆 {{milestone_title}}",
            "body": "{{milestone_body}}",
        },
    },
    # --- system (NOTIF_TYPE_SYSTEM) — generic fallback ---------------------
    "system": {
        "fr": {
            "title": "{{title}}",
            "body": "{{body}}",
        },
        "en": {
            "title": "{{title}}",
            "body": "{{body}}",
        },
    },
}


_VAR_RE = re.compile(r"\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}\}")


def _normalize_locale(locale: str | None) -> Locale:
    """Return a supported locale, falling back to DEFAULT_LOCALE."""
    if locale is None:
        return DEFAULT_LOCALE
    loc = locale.strip().lower()[:2]
    if loc in SUPPORTED_LOCALES:
        return loc  # type: ignore[return-value]
    logger.debug("Unsupported locale %r, falling back to %s", locale, DEFAULT_LOCALE)
    return DEFAULT_LOCALE


def _substitute(template_str: str, context: dict) -> str:
    """Replace {{var}} with context values. Missing vars → [var] + warning."""

    def _repl(match: re.Match[str]) -> str:
        var = match.group(1)
        if var not in context or context[var] is None:
            logger.warning("Missing template variable: %s", var)
            return f"[{var}]"
        return str(context[var])

    return _VAR_RE.sub(_repl, template_str)


def render(
    template_key: str,
    locale: str | None,
    context: dict | None = None,
) -> NotificationContent:
    """Render a notification template.

    Args:
        template_key: Key in TEMPLATES (e.g. "session_reminder").
        locale: "fr" or "en". Unknown locales fall back to DEFAULT_LOCALE.
        context: Variables to interpolate.

    Returns:
        NotificationContent with interpolated title and body.

    Raises:
        KeyError: If template_key is not registered.
    """
    if template_key not in TEMPLATES:
        raise KeyError(f"Unknown notification template: {template_key!r}")

    ctx = context or {}
    loc = _normalize_locale(locale)

    variants = TEMPLATES[template_key]
    tpl = variants.get(loc) or variants[DEFAULT_LOCALE]

    return NotificationContent(
        title=_substitute(tpl["title"], ctx),
        body=_substitute(tpl["body"], ctx),
    )


def list_templates() -> list[str]:
    """Return all registered template keys."""
    return sorted(TEMPLATES.keys())


def get_template_raw(template_key: str, locale: str | None) -> dict[str, str]:
    """Return the raw template dict (before interpolation)."""
    if template_key not in TEMPLATES:
        raise KeyError(f"Unknown notification template: {template_key!r}")
    loc = _normalize_locale(locale)
    variants = TEMPLATES[template_key]
    return dict(variants.get(loc) or variants[DEFAULT_LOCALE])
