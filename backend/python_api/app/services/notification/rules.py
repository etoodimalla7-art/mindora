"""Notification business rules.

Each rule is a pure function that takes the current time + user context and
returns a NotificationIntent (to be rendered + sent) or None (no-op).

Rules are intentionally free of I/O: they receive everything they need via
arguments. This makes them:
- deterministic (testable with a fixed `now`)
- composable (the engine in 12B.3 calls them all)
- side-effect free (no DB access, no HTTP, no logging beyond debug)

The engine is responsible for:
- dedup lookup (via `dedup_key`)
- template rendering
- persistence + provider dispatch
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Iterable

# ---------------------------------------------------------------------------
# Intent model
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class NotificationIntent:
    """A rule's decision to notify a user.

    Attributes:
        template_key: Key in TEMPLATES (rendered later by engine).
        context: Variables to interpolate (user_name, subject_name, ...).
        priority: 1 = highest, 5 = lowest. Used for anti-spam ordering.
        dedup_key: Unique key per "logical notification". If a Notification
            row already exists with this dedup_key for this user, skip.
        user_id: UUID of the target user (as str).
    """

    template_key: str
    context: dict[str, Any]
    priority: int
    dedup_key: str
    user_id: str


# ---------------------------------------------------------------------------
# Helper: extract a friendly first name for templates
# ---------------------------------------------------------------------------


def _first_name(user: Any) -> str:
    """Best-effort first name. Falls back to 'ami(e)' / 'friend'."""
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
# RULE 1 — study_reminder
# ---------------------------------------------------------------------------


def rule_study_reminder(
    *,
    now: datetime,
    user: Any,
    upcoming_sessions: Iterable[Any],
    window_minutes: int = 15,
) -> NotificationIntent | None:
    """Fire if a session starts within the next `window_minutes` (default 15).

    `upcoming_sessions` must be an iterable of objects with:
      - id (UUID-like)
      - subject_name (str)  OR  subject.name
      - scheduled_at (datetime, tz-aware or naive)
    """
    now = _as_utc(now)
    window_end = now + timedelta(minutes=window_minutes)
    best: tuple[Any, int] | None = None  # (session, minutes_left)

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
        template_key="study_reminder",
        context={
            "user_name": _first_name(user),
            "subject_name": subject_name,
            "minutes": minutes_left,
        },
        priority=1,
        dedup_key=f"study_reminder:{sid}",
        user_id=str(getattr(user, "id", "")),
    )


# ---------------------------------------------------------------------------
# RULE 2 — streak_alert
# ---------------------------------------------------------------------------


def rule_streak_alert(
    *,
    now: datetime,
    user: Any,
    streak_days: int,
    sessions_completed_today: int,
    threshold_hour_local: int = 20,
    local_offset_hours: int = 1,  # Cameroon = UTC+1
) -> NotificationIntent | None:
    """Fire if it's past 20h local, user has a streak, but no session today."""
    if streak_days <= 0:
        return None
    if sessions_completed_today > 0:
        return None

    now = _as_utc(now)
    local_now = now + timedelta(hours=local_offset_hours)
    if local_now.hour < threshold_hour_local:
        return None

    # Dedup once per calendar day (local)
    day_key = local_now.strftime("%Y-%m-%d")

    return NotificationIntent(
        template_key="streak_alert",
        context={
            "user_name": _first_name(user),
            "streak_days": streak_days,
        },
        priority=2,
        dedup_key=f"streak_alert:{day_key}",
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
    """Fire at J-7, J-3, J-1 before an exam.

    `exam` must have: id, name (or title), exam_date (datetime), subject_name
    """
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
        template_key="exam_countdown",
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
# RULE 4 — plan_nudge
# ---------------------------------------------------------------------------


def rule_plan_nudge(
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
        # Never started: give a nudge after creation + inactivity_days
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
    # Dedup once per ISO week per plan
    year, week, _ = now.isocalendar()

    return NotificationIntent(
        template_key="plan_nudge",
        context={
            "user_name": _first_name(user),
            "plan_name": plan_name,
        },
        priority=3,
        dedup_key=f"plan_nudge:{plan_id}:{year}-W{week}",
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
        template_key="subscription_expiring",
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

# Rules are exposed as a tuple so the engine can iterate in a stable order
# (also useful for admin listing & tests).
ALL_RULES: tuple[RuleFn, ...] = (
    rule_study_reminder,
    rule_streak_alert,
    rule_exam_countdown,
    rule_plan_nudge,
    rule_subscription_expiring,
)


def evaluate_rules(rules: Iterable[RuleFn], **kwargs: Any) -> list[NotificationIntent]:
    """Run every rule with the given kwargs, return non-None intents.

    Note: rules accept keyword-only args (see signatures above). Passing a
    superset of kwargs is fine — each rule ignores what it doesn't need,
    *provided* the rule accepts `**kwargs`. Since our rules do NOT take
    `**kwargs`, the caller must pass only the kwargs a rule needs.

    Instead, we filter by inspecting the rule's signature.
    """
    import inspect

    results: list[NotificationIntent] = []
    for rule in rules:
        sig = inspect.signature(rule)
        accepted = {name for name in sig.parameters if name not in ("self", "cls")}
        # Note: all our rules use keyword-only args (after *), so we filter.
        applicable = {k: v for k, v in kwargs.items() if k in accepted}
        try:
            intent = rule(**applicable)
        except TypeError:
            # Missing required kwarg for this rule → skip silently.
            continue
        if intent is not None:
            results.append(intent)
    return results