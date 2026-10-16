"""Realtime notification hooks.

Called from business services when something happens (session completed,
document ready, mock exam generated). All hooks are NON-BLOCKING: they
swallow exceptions so the caller's transaction stays intact.

Pattern:
    from app.services.notification.hooks import on_session_completed
    ...
    session.status = "completed"
    session.completed_at = datetime.now(timezone.utc)
    await db.flush()
    await on_session_completed(db, user=user, session=session)  # non-blocking
"""

from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.notifications.factory import get_notification_provider
from app.models.notification import NotificationPreference
from app.models.plan import StudySession
from app.models.user import User
from app.services.notification.engine import NotificationEngine
from app.services.notification.rules import NotificationIntent

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Internal helpers
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


def _first_name(user: Any) -> str:
    full = getattr(user, "full_name", None) or getattr(user, "name", None)
    if not full:
        return "ami(e)"
    return str(full).strip().split()[0] or "ami(e)"


async def _compute_streak_today(
    db: AsyncSession, user_id: Any, *, today: date
) -> int:
    """Current consecutive-day streak (from completed sessions)."""
    from datetime import timedelta

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

    streak = 0
    expected = today
    for d in days:
        if d == expected:
            streak += 1
            expected = expected - timedelta(days=1)
        elif d == expected - timedelta(days=1) and streak == 0:
            streak += 1
            expected = d - timedelta(days=1)
        else:
            break
    return streak


async def _safe_dispatch(
    db: AsyncSession,
    intent: NotificationIntent,
    prefs: NotificationPreference | None,
) -> None:
    """Dispatch via engine, swallowing all errors (non-blocking contract)."""
    try:
        provider = get_notification_provider()
        engine = NotificationEngine(db, provider, locale=_user_locale(prefs))
        await engine.dispatch_intent(intent)
    except Exception as exc:  # noqa: BLE001
        logger.exception("Notification hook failed (non-fatal): %s", exc)


# ---------------------------------------------------------------------------
# HOOK 1 — session completed
# ---------------------------------------------------------------------------


async def on_session_completed(
    db: AsyncSession,
    *,
    user: User,
    session: StudySession,
) -> None:
    """Called right after a StudySession is marked completed.

    Sends a 'session_completed' notification. Never raises.
    """
    try:
        prefs = await _get_user_prefs(db, user.id)
        today = datetime.now(timezone.utc).date()
        streak = await _compute_streak_today(db, user.id, today=today)

        subject_name = session.subject or session.title or "Session"
        sid = str(session.id)

        intent = NotificationIntent(
            template_key="session_completed",
            context={
                "user_name": _first_name(user),
                "subject_name": subject_name,
                "streak_days": streak,
            },
            priority=3,
            dedup_key=f"session_completed:{sid}",
            user_id=str(user.id),
        )
        await _safe_dispatch(db, intent, prefs)
    except Exception as exc:  # noqa: BLE001
        logger.exception("on_session_completed failed (non-fatal): %s", exc)


# ---------------------------------------------------------------------------
# HOOK 2 — document ready
# ---------------------------------------------------------------------------


async def on_document_ready(
    db: AsyncSession,
    *,
    user: User,
    document: Any,
) -> None:
    """Called when a document has been uploaded + processed by RAG."""
    try:
        prefs = await _get_user_prefs(db, user.id)
        title = (
            getattr(document, "title", None)
            or getattr(document, "filename", None)
            or "Document"
        )
        doc_id = str(getattr(document, "id", "unknown"))

        intent = NotificationIntent(
            template_key="document_ready",
            context={
                "user_name": _first_name(user),
                "document_title": title,
            },
            priority=3,
            dedup_key=f"document_ready:{doc_id}",
            user_id=str(user.id),
        )
        await _safe_dispatch(db, intent, prefs)
    except Exception as exc:  # noqa: BLE001
        logger.exception("on_document_ready failed (non-fatal): %s", exc)


# ---------------------------------------------------------------------------
# HOOK 3 — mock exam generated
# ---------------------------------------------------------------------------


async def on_mock_exam_generated(
    db: AsyncSession,
    *,
    user: User,
    mock_exam: Any,
) -> None:
    """Called when a mock exam has finished generating."""
    try:
        prefs = await _get_user_prefs(db, user.id)
        exam_id = str(getattr(mock_exam, "id", "unknown"))
        subject = (
            getattr(mock_exam, "subject", None)
            or getattr(mock_exam, "title", None)
            or "Mock exam"
        )

        intent = NotificationIntent(
            template_key="milestone",
            context={
                "milestone_title": "🎯 Ton mock exam est prêt !",
                "milestone_body": f"'{subject}' t'attend. Bonne chance !",
            },
            priority=2,
            dedup_key=f"mock_exam_ready:{exam_id}",
            user_id=str(user.id),
        )
        await _safe_dispatch(db, intent, prefs)
    except Exception as exc:  # noqa: BLE001
        logger.exception("on_mock_exam_generated failed (non-fatal): %s", exc)
