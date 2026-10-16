"""Notification jobs — run by the scheduler.

Each job:
    1. Queries the relevant users/entities
    2. Runs the corresponding rule
    3. Dispatches via NotificationEngine

Jobs are idempotent thanks to dedup_key. They swallow per-user errors so one
bad user doesn't kill the batch.

All timestamps are tz-aware. Rule functions handle the dedup/threshold logic.
"""

from __future__ import annotations

import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.notifications.factory import get_notification_provider
from app.models.notification import NotificationPreference
from app.models.plan import StudyPlan, StudySession
from app.models.subscription import Subscription
from app.models.user import User
from app.services.notification.engine import NotificationEngine
from app.services.notification.rules import (
    NotificationIntent,
    rule_exam_countdown,
    rule_inactivity,
    rule_session_reminder,
    rule_streak,
    rule_subscription_expiring,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


async def _get_user_prefs(
    db: AsyncSession, user_id: Any
) -> NotificationPreference | None:
    stmt = select(NotificationPreference).where(
        NotificationPreference.user_id == user_id
    )
    return (await db.execute(stmt)).scalar_one_or_none()


def _user_locale(prefs: NotificationPreference | None) -> str:
    if prefs is None:
        return "fr"
    tz = (prefs.timezone or "").lower()
    if tz.startswith("africa/") or tz.startswith("europe/paris"):
        return "fr"
    return "en"


async def _safe_dispatch(
    db: AsyncSession,
    provider: Any,
    intent: NotificationIntent,
    prefs: NotificationPreference | None,
) -> None:
    try:
        engine = NotificationEngine(db, provider, locale=_user_locale(prefs))
        await engine.dispatch_intent(intent)
    except Exception as exc:  # noqa: BLE001
        logger.exception("Job dispatch failed user=%s: %s", intent.user_id, exc)


# ---------------------------------------------------------------------------
# JOB 1 — upcoming session reminders (every 5 min)
# ---------------------------------------------------------------------------


async def job_scan_upcoming_sessions(
    db: AsyncSession,
    *,
    now: datetime | None = None,
    window_minutes: int = 15,
) -> int:
    """Scan scheduled study sessions starting within `window_minutes`."""
    now = now or datetime.now(timezone.utc)
    window_end = now + timedelta(minutes=window_minutes)

    stmt = (
        select(StudySession, User)
        .join(User, User.id == StudySession.user_id)
        .where(
            StudySession.status == "scheduled",
            StudySession.scheduled_for >= now,
            StudySession.scheduled_for <= window_end,
        )
    )
    rows = (await db.execute(stmt)).all()

    provider = get_notification_provider()
    processed = 0
    for session, user in rows:
        prefs = await _get_user_prefs(db, user.id)
        # Adapt StudySession → rule shape (id, subject_name, scheduled_at)
        proxy = _SessionProxy(session)
        intent = rule_session_reminder(
            now=now,
            user=user,
            upcoming_sessions=[proxy],
            window_minutes=window_minutes,
        )
        if intent is not None:
            await _safe_dispatch(db, provider, intent, prefs)
            processed += 1
    logger.info("job_scan_upcoming_sessions processed=%d", processed)
    return processed


class _SessionProxy:
    """Adapt a StudySession to the shape expected by rule_session_reminder."""

    __slots__ = ("id", "subject_name", "scheduled_at", "_raw")

    def __init__(self, session: StudySession) -> None:
        self.id = session.id
        self.subject_name = session.subject or session.title or "Session"
        self.scheduled_at = session.scheduled_for
        self._raw = session


# ---------------------------------------------------------------------------
# JOB 2 — exam countdown (daily 09h local)
# ---------------------------------------------------------------------------


async def job_scan_exam_countdown(
    db: AsyncSession,
    *,
    now: datetime | None = None,
) -> int:
    """Scan active study plans with target_date in (today, today+7d]."""
    now = now or datetime.now(timezone.utc)
    today = now.date()
    horizon = today + timedelta(days=8)

    stmt = (
        select(StudyPlan, User)
        .join(User, User.id == StudyPlan.user_id)
        .where(
            StudyPlan.is_active.is_(True),
            StudyPlan.target_date.is_not(None),
            StudyPlan.target_date >= today,
            StudyPlan.target_date <= horizon,
        )
    )
    rows = (await db.execute(stmt)).all()

    provider = get_notification_provider()
    processed = 0
    for plan, user in rows:
        prefs = await _get_user_prefs(db, user.id)
        proxy = _ExamProxy(plan)
        intent = rule_exam_countdown(now=now, user=user, exam=proxy)
        if intent is not None:
            await _safe_dispatch(db, provider, intent, prefs)
            processed += 1
    logger.info("job_scan_exam_countdown processed=%d", processed)
    return processed


class _ExamProxy:
    """Adapt a StudyPlan (with target_date) to the exam shape."""

    __slots__ = ("id", "name", "exam_date", "subject_name", "_raw")

    def __init__(self, plan: StudyPlan) -> None:
        self.id = plan.id
        self.name = plan.exam_name or plan.title or "Examen"
        self.subject_name = plan.subject or plan.exam_name or plan.title or "Examen"
        # rule_exam_countdown expects datetime
        self.exam_date = datetime.combine(
            plan.target_date, datetime.min.time(), tzinfo=timezone.utc
        )
        self._raw = plan


# ---------------------------------------------------------------------------
# JOB 3 — streak alerts (daily 20h local)
# ---------------------------------------------------------------------------


async def _compute_streak(
    db: AsyncSession, user_id: Any, *, today: date
) -> tuple[int, int]:
    """Return (streak_days, sessions_completed_today).

    Streak = consecutive days with at least one completed StudySession.
    Sessions_today = count of completed sessions today (UTC date).
    """
    # Days with at least one completed session, last 60 days
    since = today - timedelta(days=60)
    stmt = (
        select(func.date(StudySession.completed_at))
        .where(
            StudySession.user_id == user_id,
            StudySession.completed_at.is_not(None),
            StudySession.completed_at >= datetime.combine(
                since, datetime.min.time(), tzinfo=timezone.utc
            ),
        )
        .distinct()
    )
    rows = (await db.execute(stmt)).all()
    days = sorted({r[0] for r in rows if r[0] is not None}, reverse=True)

    # Compute streak from today backwards
    streak = 0
    if days:
        cursor = today if days[0] == today else today
        # If the first day is not today, streak breaks unless yesterday starts it
        expected = today
        for d in days:
            if d == expected:
                streak += 1
                expected = expected - timedelta(days=1)
            elif d == expected - timedelta(days=1) and streak == 0:
                # Allow "yesterday" to start a streak (user still has time today)
                streak += 1
                expected = d - timedelta(days=1)
            else:
                break

    # Sessions today
    today_start = datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc)
    tomorrow_start = today_start + timedelta(days=1)
    stmt_today = select(func.count(StudySession.id)).where(
        StudySession.user_id == user_id,
        StudySession.completed_at.is_not(None),
        StudySession.completed_at >= today_start,
        StudySession.completed_at < tomorrow_start,
    )
    sessions_today = int((await db.execute(stmt_today)).scalar() or 0)
    return streak, sessions_today


async def job_scan_streaks(
    db: AsyncSession,
    *,
    now: datetime | None = None,
) -> int:
    """Alert users whose streak is at risk (past 20h local, no session today)."""
    now = now or datetime.now(timezone.utc)
    today = now.date()

    # Iterate over users who had activity in the last 60 days (avoid full scan)
    since = today - timedelta(days=60)
    stmt = (
        select(User)
        .join(StudySession, StudySession.user_id == User.id)
        .where(StudySession.completed_at.is_not(None))
        .where(StudySession.completed_at >= datetime.combine(
            since, datetime.min.time(), tzinfo=timezone.utc
        ))
        .distinct()
    )
    users = (await db.execute(stmt)).scalars().all()

    provider = get_notification_provider()
    processed = 0
    for user in users:
        streak, sessions_today = await _compute_streak(db, user.id, today=today)
        prefs = await _get_user_prefs(db, user.id)
        intent = rule_streak(
            now=now,
            user=user,
            streak_days=streak,
            sessions_completed_today=sessions_today,
        )
        if intent is not None:
            await _safe_dispatch(db, provider, intent, prefs)
            processed += 1
    logger.info("job_scan_streaks processed=%d", processed)
    return processed


# ---------------------------------------------------------------------------
# JOB 4 — inactivity nudges (daily 10h local)
# ---------------------------------------------------------------------------


async def job_scan_inactivity(
    db: AsyncSession,
    *,
    now: datetime | None = None,
) -> int:
    """Nudge active plans inactive for > 3 days."""
    now = now or datetime.now(timezone.utc)

    stmt = (
        select(StudyPlan, User)
        .join(User, User.id == StudyPlan.user_id)
        .where(StudyPlan.is_active.is_(True))
    )
    rows = (await db.execute(stmt)).all()

    provider = get_notification_provider()
    processed = 0
    for plan, user in rows:
        # Last activity = max(updated_at, latest completed session for this plan)
        stmt_last = select(func.max(StudySession.completed_at)).where(
            StudySession.plan_id == plan.id,
            StudySession.completed_at.is_not(None),
        )
        last_session = (await db.execute(stmt_last)).scalar()
        candidates = [plan.updated_at]
        if last_session is not None:
            candidates.append(last_session)
        last_activity = max(c for c in candidates if c is not None)

        prefs = await _get_user_prefs(db, user.id)
        proxy = _PlanProxy(plan)
        intent = rule_inactivity(
            now=now,
            user=user,
            plan=proxy,
            last_activity_at=last_activity,
        )
        if intent is not None:
            await _safe_dispatch(db, provider, intent, prefs)
            processed += 1
    logger.info("job_scan_inactivity processed=%d", processed)
    return processed


class _PlanProxy:
    """Adapt a StudyPlan to the shape expected by rule_inactivity."""

    __slots__ = ("id", "name", "status", "created_at", "_raw")

    def __init__(self, plan: StudyPlan) -> None:
        self.id = plan.id
        self.name = plan.title or plan.subject or "Plan d'étude"
        # rule_inactivity checks status == "active"
        self.status = "active" if plan.is_active else "completed"
        self.created_at = plan.created_at
        self._raw = plan


# ---------------------------------------------------------------------------
# JOB 5 — subscription expiry (daily 10h30 local)
# ---------------------------------------------------------------------------


async def job_scan_subscriptions(
    db: AsyncSession,
    *,
    now: datetime | None = None,
) -> int:
    """Warn users whose subscription expires at J-7 or J-1."""
    now = now or datetime.now(timezone.utc)

    stmt = (
        select(Subscription, User)
        .join(User, User.id == Subscription.user_id)
        .where(Subscription.status.in_(("active", "grace")))
        .where(Subscription.current_period_end.is_not(None))
    )
    rows = (await db.execute(stmt)).all()

    provider = get_notification_provider()
    processed = 0
    for sub, user in rows:
        prefs = await _get_user_prefs(db, user.id)
        intent = rule_subscription_expiring(now=now, user=user, subscription=sub)
        if intent is not None:
            await _safe_dispatch(db, provider, intent, prefs)
            processed += 1
    logger.info("job_scan_subscriptions processed=%d", processed)
    return processed
