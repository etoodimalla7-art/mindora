"""Notification business rules.

Each rule is a pure function that takes the current time + user context and
returns a NotificationIntent (to be rendered + sent) or None (no-op).

Rules are intentionally free of I/O: they receive everything they need via
arguments. This makes them deterministic, composable, and easily testable.

The engine (see engine.py) is responsible for:
- dedup lookup (via `dedup_key`)
- template rendering
- persistence + provider dispatch
"""

from __future__ import annotations

import inspect
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Iterable

from app.models.notification import (
    NOTIF_TYPE_EXAM_COUNTDOWN,
    NOTIF_TYPE_INACTIVITY,
    NOTIF_TYPE_SESSION_REMINDER,
    NOTIF_TYPE_STREAK,
    NOTIF_TYPE_SUBSCRIPTION_EXPIRING,
)

# ---------------------------------------------------------------------------
# Intent model
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class NotificationIntent:
    """A rule's decision to notify a user."""

    template_key: str
    context: dict[str, Any]
    priority: int
    dedup_key: str
    user_id: str


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _first_name(user: Any) -> str:
    """Best-effort first name. Falls back to 'ami(e)'."""
    full = getattr(user, "full_name", None) or getattr(user, "name", None)
    if not full:
        return "ami(e)"
    return str(full).strip().split()[0] or "ami(e)"


def _as_utc(dt: datetime) -> datetime:
    """Ensure a datetime is timezone-aware (UTC)."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


# ---------------------------------------------------------------------------
# RULE 1 — session_reminder
# ---------------------------------------------------------------------------


def rule_session_reminder(
    *,
    now: datetime,
    user: Any,
    upcoming_sessions: Iterable[Any],
    window_minutes: int = 15,
) -> NotificationIntent | None:
    """Fire if a session starts within the next `window_minutes` (default 15).

    `upcoming_sessions` items must have: id, subject_name (or subject.name),
    scheduled_at (datetime).
    """
    now = _as_utc(now)
    window_end = now + timedelta(minutes=window_minutes)
    best: tuple[Any, int] | None = None

    for s in upcoming_sessions:
        sched = _as_utc(getattr(s, "scheduled_at"))
        if now <= sched <= window_end:
            minutes_left = max(1, int((sched - now).total_seconds() // 60))
            if best is None or minutes_left < best[1]:
                best = (s, minutes_left)

    if best is None:
        return None

    session, minutes_left = best
    subject_name = (
        getattr(session, "subject_name", None)
        or getattr(getattr(session, "subject", None), "name", None)
        or "Session"
    )
    sid = str(getattr(session, "id", "unknown"))

    return NotificationIntent(
        template_key=NOTIF_TYPE_SESSION_REMINDER,
        context={
            "user_name": _first_name(user),
            "subject_name": subject_name,
            "minutes": minutes_left,
        },
        priority=1,
        dedup_key=f"session_reminder:{sid}",
        user_id=str(getattr(user, "id", "")),
    )


# ---------------------------------------------------------------------------
# RULE 2 — streak
# ---------------------------------------------------------------------------


def rule_streak(
    *,
    now: datetime,
    user: Any,
    streak_days: int,
    sessions_completed_today: int,
    threshold_hour_local: int = 20,
    local_offset_hours: int = 1,  # Cameroon = UTC+1
) -> NotificationIntent | None:
    """Fire if past 20h local, user has a streak, but no session today."""
    if streak_days <= 0:
        return None
    if sessions_completed_today > 0:
        return None

    now = _as_utc(now)
    local_now = now + timedelta(hours=local_offset_hours)
    if local_now.hour < threshold_hour_local:
        return None

    day_key = local_now.strftime("%Y-%m-%d")

    return NotificationIntent(
        template_key=NOTIF_TYPE_STREAK,
        context={
            "user_name": _first_name(user),
            "streak_days": streak_days,
        },
        priority=2,
        dedup_key=f"streak:{day_key}",
        user_id=str(getattr(user, "id", "")),
    )


# ---------------------------------------------------------------------------
# RULE 3 — exam_countdown
# ---------------------------------------------------------------------------


_EXAM_THRESHOLDS: tuple[int, ...] = (7, 3, 1)


def rule_exam_countdown(
    *,
    now: datetime,
    user: Any,
    exam: Any,
) -> NotificationIntent | None:
    """Fire at J-7, J-3, J-1 before an exam."""
    if exam is None:
        return None

    exam_dt = _as_utc(getattr(exam, "exam_date"))
    now = _as_utc(now)
    days_left = (exam_dt.date() - now.date()).days

    if days_left not in _EXAM_THRESHOLDS:
        return None

    exam_id = str(getattr(exam, "id", "unknown"))
    subject_name = (
        getattr(exam, "subject_name", None)
        or getattr(exam, "name", None)
        or getattr(exam, "title", None)
        or "Examen"
    )

    return NotificationIntent(
        template_key=NOTIF_TYPE_EXAM_COUNTDOWN,
        context={
            "user_name": _first_name(user),
            "days_left": days_left,
            "subject_name": subject_name,
        },
        priority=1,
        dedup_key=f"exam_countdown:{exam_id}:J-{days_left}",
        user_id=str(getattr(user, "id", "")),
    )


# ---------------------------------------------------------------------------
# RULE 4 — inactivity (plan nudge)
# ---------------------------------------------------------------------------


def rule_inactivity(
    *,
    now: datetime,
    user: Any,
    plan: Any,
    last_activity_at: datetime | None,
    inactivity_days: int = 3,
) -> NotificationIntent | None:
    """Fire if an active plan has had no activity for > `inactivity_days`."""
    if plan is None:
        return None
    if getattr(plan, "status", "active") != "active":
        return None
    if last_activity_at is None:
        created = getattr(plan, "created_at", None)
        if created is None:
            return None
        last_activity_at = created

    now = _as_utc(now)
    last = _as_utc(last_activity_at)
    if (now - last) < timedelta(days=inactivity_days):
        return None

    plan_id = str(getattr(plan, "id", "unknown"))
    plan_name = getattr(plan, "name", None) or getattr(plan, "title", None) or "Plan"
    year, week, _ = now.isocalendar()

    return NotificationIntent(
        template_key=NOTIF_TYPE_INACTIVITY,
        context={
            "user_name": _first_name(user),
            "plan_name": plan_name,
        },
        priority=3,
        dedup_key=f"inactivity:{plan_id}:{year}-W{week}",
        user_id=str(getattr(user, "id", "")),
    )


# ---------------------------------------------------------------------------
# RULE 5 — subscription_expiring
# ---------------------------------------------------------------------------


_SUB_THRESHOLDS: tuple[int, ...] = (7, 1)


def rule_subscription_expiring(
    *,
    now: datetime,
    user: Any,
    subscription: Any,
) -> NotificationIntent | None:
    """Fire at J-7 and J-1 before subscription expiry."""
    if subscription is None:
        return None
    if getattr(subscription, "status", "active") not in ("active", "grace"):
        return None

    end = getattr(subscription, "current_period_end", None) or getattr(
        subscription, "expires_at", None
    )
    if end is None:
        return None

    now = _as_utc(now)
    end_utc = _as_utc(end)
    days_left = (end_utc.date() - now.date()).days

    if days_left not in _SUB_THRESHOLDS:
        return None

    sub_id = str(getattr(subscription, "id", "unknown"))

    return NotificationIntent(
        template_key=NOTIF_TYPE_SUBSCRIPTION_EXPIRING,
        context={
            "user_name": _first_name(user),
            "days_until_expiry": days_left,
        },
        priority=1,
        dedup_key=f"subscription_expiring:{sub_id}:J-{days_left}",
        user_id=str(getattr(user, "id", "")),
    )


# ---------------------------------------------------------------------------
# Registry + orchestrator
# ---------------------------------------------------------------------------


RuleFn = Callable[..., NotificationIntent | None]

ALL_RULES: tuple[RuleFn, ...] = (
    rule_session_reminder,
    rule_streak,
    rule_exam_countdown,
    rule_inactivity,
    rule_subscription_expiring,
)

# Backwards-compat alias (old name)
rule_study_reminder = rule_session_reminder
rule_streak_alert = rule_streak
rule_plan_nudge = rule_inactivity


def evaluate_rules(rules: Iterable[RuleFn], **kwargs: Any) -> list[NotificationIntent]:
    """Run every rule with only the kwargs it accepts. Return non-None intents."""
    results: list[NotificationIntent] = []
    for rule in rules:
        sig = inspect.signature(rule)
        accepted = {name for name in sig.parameters if name not in ("self", "cls")}
        applicable = {k: v for k, v in kwargs.items() if k in accepted}
        try:
            intent = rule(**applicable)
        except TypeError:
            # Missing required kwarg → skip this rule silently.
            continue
        if intent is not None:
            results.append(intent)
    return results
