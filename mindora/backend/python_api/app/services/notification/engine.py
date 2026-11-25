"""Notification Engine — orchestrates rules → render → persist → dispatch.

Flow for each intent:
    1. dedup check (dedup_key already in notifications?)
    2. load user preferences (opt-out, quiet hours, daily limit)
    3. render template (FR/EN)
    4. persist Notification row (status=pending)
    5. fetch user's active devices
    6. send via provider (send_batch)
    7. update status (sent / failed / no_device)

The engine is safe to call concurrently: dedup uses a partial unique
index on (user_id, dedup_key), so a race just triggers IntegrityError
which we catch and treat as duplicate.
"""

from __future__ import annotations

import logging
from datetime import datetime, time as dt_time, timezone
from typing import Callable, Iterable
from uuid import UUID
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.integrations.notifications.provider import (
    NotificationProvider,
    PushMessage,
)
from app.models.notification import (
    NOTIF_STATUS_FAILED,
    NOTIF_STATUS_NO_DEVICE,
    NOTIF_STATUS_PENDING,
    NOTIF_STATUS_SENT,
    NOTIF_STATUS_SKIPPED_DAILY_LIMIT,
    NOTIF_STATUS_SKIPPED_DUPLICATE,
    NOTIF_STATUS_SKIPPED_PREF,
    NOTIF_STATUS_SKIPPED_QUIET_HOURS,
    Device,
    Notification,
    NotificationPreference,
    NotificationRule,
)
from app.services.notification.rules import NotificationIntent
from app.services.notification.templates import render

logger = logging.getLogger(__name__)


# Map template_key → NotificationPreference boolean field name.
_PREF_FIELD_BY_TYPE: dict[str, str] = {
    "session_reminder": "session_reminders",
    "exam_countdown": "exam_countdown",
    "streak": "streak_reminders",
    "milestone": "milestones",
    "inactivity": "inactivity_nudges",
    "weak_topic": "weak_topic_alerts",
}

# Fallback preference used when no row exists for the user.
_DEFAULT_PREFS = {
    "enabled": True,
    "session_reminders": True,
    "exam_countdown": True,
    "streak_reminders": True,
    "milestones": True,
    "inactivity_nudges": True,
    "weak_topic_alerts": True,
    "max_per_day": 3,
    "quiet_hours_start": 22,
    "quiet_hours_end": 7,
    "reminder_minutes_before": 15,
    "timezone": "Africa/Douala",
}


class NotificationEngine:
    """Orchestrates intents → notifications."""

    def __init__(
        self,
        db: AsyncSession,
        provider: NotificationProvider,
        *,
        locale: str = "fr",
        enforce_quiet_hours: bool = True,
        enforce_daily_limit: bool = True,
        now_fn: Callable[[], datetime] | None = None,
    ) -> None:
        self.db = db
        self.provider = provider
        self.locale = locale
        self.enforce_quiet_hours = enforce_quiet_hours
        self.enforce_daily_limit = enforce_daily_limit
        self._now_fn = now_fn or (lambda: datetime.now(timezone.utc))

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def dispatch_intent(
        self, intent: NotificationIntent
    ) -> Notification | None:
        """Process a single intent. Returns the persisted Notification or None
        if skipped (duplicate)."""
        user_id = UUID(intent.user_id)

        # 1. dedup
        if await self._is_duplicate(user_id, intent.dedup_key):
            logger.debug("Dedup skip: %s / %s", user_id, intent.dedup_key)
            return None

        # 2. rule + preferences + quiet hours + daily limit
        rule = await self._get_rule(intent.template_key)
        if rule is not None and not rule.enabled:
            return await self._persist(
                intent, user_id, status=NOTIF_STATUS_SKIPPED_PREF
            )

        prefs = await self._get_or_create_prefs(user_id)
        skip_reason = self._check_prefs(intent, prefs, rule=rule)
        if skip_reason is not None:
            notif = await self._persist(
                intent, user_id, status=skip_reason
            )
            return notif

        if self.enforce_daily_limit:
            max_day = prefs.max_per_day
            if rule is not None and rule.max_per_day is not None:
                max_day = min(max_day, rule.max_per_day)
            sent_today = await self._count_sent_today(user_id, prefs.timezone)
            if sent_today >= max_day:
                return await self._persist(
                    intent, user_id, status=NOTIF_STATUS_SKIPPED_DAILY_LIMIT
                )

        # 3. render
        content = render(intent.template_key, self.locale, intent.context)

        # 4. persist (pending)
        notif = await self._persist(
            intent,
            user_id,
            status=NOTIF_STATUS_PENDING,
            title=content.title,
            body=content.body,
        )
        if notif is None:
            # IntegrityError during insert → duplicate race
            return None

        # 5. devices
        tokens = await self._get_active_device_tokens(user_id)
        if not tokens:
            notif.status = NOTIF_STATUS_NO_DEVICE
            await self.db.flush()
            logger.info("No devices for user=%s — notification stored only", user_id)
            return notif

        # 6. dispatch
        messages = [
            PushMessage(
                token=tok,
                title=content.title,
                body=content.body,
                deep_link=notif.deep_link,
                data={
                    "notification_id": str(notif.id),
                    "template_key": intent.template_key,
                },
                priority="high" if intent.priority <= 2 else "normal",
            )
            for tok in tokens
        ]
        results = await self.provider.send_batch(messages)

        # 7. update status
        ok = any(r.success for r in results)
        if ok:
            notif.status = NOTIF_STATUS_SENT
            notif.sent_at = self._now_fn()
            first_id = next((r.message_id for r in results if r.success), None)
            if first_id:
                notif.fcm_message_id = first_id
        else:
            notif.status = NOTIF_STATUS_FAILED
            logger.warning(
                "All sends failed for notif=%s errors=%s",
                notif.id,
                [r.error for r in results],
            )
        await self.db.flush()
        return notif

    async def dispatch_intents(
        self, intents: Iterable[NotificationIntent]
    ) -> list[Notification]:
        """Dispatch multiple intents, sorted by priority (1 first)."""
        ordered = sorted(intents, key=lambda i: i.priority)
        results: list[Notification] = []
        for intent in ordered:
            try:
                notif = await self.dispatch_intent(intent)
                if notif is not None:
                    results.append(notif)
            except Exception as exc:  # noqa: BLE001
                logger.exception("Intent dispatch failed: %s", exc)
        return results

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    async def _is_duplicate(self, user_id: UUID, dedup_key: str) -> bool:
        stmt = select(Notification.id).where(
            Notification.user_id == user_id,
            Notification.dedup_key == dedup_key,
        )
        return (await self.db.execute(stmt)).first() is not None

    async def _get_rule(self, template_key: str) -> NotificationRule | None:
        stmt = select(NotificationRule).where(
            NotificationRule.rule_key == template_key
        )
        return (await self.db.execute(stmt)).scalar_one_or_none()

    async def _get_or_create_prefs(self, user_id: UUID) -> NotificationPreference:
        stmt = select(NotificationPreference).where(
            NotificationPreference.user_id == user_id
        )
        prefs = (await self.db.execute(stmt)).scalar_one_or_none()
        if prefs is not None:
            return prefs

        prefs = NotificationPreference(user_id=user_id)
        self.db.add(prefs)
        try:
            await self.db.flush()
        except IntegrityError:
            await self.db.rollback()
            prefs = (
                await self.db.execute(stmt)
            ).scalar_one()
        return prefs

    def _resolve_tz(self, tz_name: str | None) -> ZoneInfo:
        try:
            return ZoneInfo(tz_name or "Africa/Douala")
        except ZoneInfoNotFoundError:
            return ZoneInfo("UTC")

    def _check_prefs(
        self,
        intent: NotificationIntent,
        prefs: NotificationPreference,
        *,
        rule: NotificationRule | None = None,
    ) -> str | None:
        """Return a skip-status code, or None if we should proceed."""
        if not prefs.enabled:
            return NOTIF_STATUS_SKIPPED_PREF

        field = _PREF_FIELD_BY_TYPE.get(intent.template_key)
        if field is not None and not getattr(prefs, field, True):
            return NOTIF_STATUS_SKIPPED_PREF

        if self.enforce_quiet_hours and self._in_quiet_hours(prefs, rule=rule):
            return NOTIF_STATUS_SKIPPED_QUIET_HOURS

        return None

    def _in_quiet_hours(
        self,
        prefs: NotificationPreference,
        *,
        rule: NotificationRule | None = None,
    ) -> bool:
        """Evaluate quiet hours in the user's configured IANA timezone."""
        now_utc = self._now_fn()
        if now_utc.tzinfo is None:
            now_utc = now_utc.replace(tzinfo=timezone.utc)
        local_dt = now_utc.astimezone(self._resolve_tz(prefs.timezone))
        hour = local_dt.hour
        start = prefs.quiet_hours_start
        end = prefs.quiet_hours_end
        if rule is not None and prefs.quiet_hours_start == 22 and prefs.quiet_hours_end == 7:
            start = rule.quiet_hours_start
            end = rule.quiet_hours_end
        if start == end:
            return False
        if start < end:
            return start <= hour < end
        # wrap-around (e.g. 22 → 7)
        return hour >= start or hour < end

    async def _count_sent_today(self, user_id: UUID, tz_name: str | None) -> int:
        tz = self._resolve_tz(tz_name)
        now_utc = self._now_fn()
        if now_utc.tzinfo is None:
            now_utc = now_utc.replace(tzinfo=timezone.utc)
        local_now = now_utc.astimezone(tz)
        local_midnight = datetime.combine(local_now.date(), dt_time.min, tzinfo=tz)
        day_start_utc = local_midnight.astimezone(timezone.utc)

        stmt = select(func.count(Notification.id)).where(
            Notification.user_id == user_id,
            Notification.created_at >= day_start_utc,
            Notification.status.in_(
                [
                    NOTIF_STATUS_PENDING,
                    NOTIF_STATUS_SENT,
                    NOTIF_STATUS_NO_DEVICE,
                    NOTIF_STATUS_FAILED,
                ]
            ),
        )
        return int((await self.db.execute(stmt)).scalar() or 0)

    async def _persist(
        self,
        intent: NotificationIntent,
        user_id: UUID,
        *,
        status: str,
        title: str | None = None,
        body: str | None = None,
    ) -> Notification | None:
        """Insert a Notification row. Returns None on dedup race."""
        notif = Notification(
            user_id=user_id,
            type=intent.template_key,
            title=title or "(pending)",
            body=body or "(pending)",
            status=status,
            dedup_key=intent.dedup_key,
            priority=intent.priority,
            template_key=intent.template_key,
            metadata_json={"intent_context": intent.context},
        )
        self.db.add(notif)
        try:
            await self.db.flush()
        except IntegrityError:
            await self.db.rollback()
            logger.debug("IntegrityError (dedup race) for %s", intent.dedup_key)
            return None
        return notif

    async def _get_active_device_tokens(self, user_id: UUID) -> list[str]:
        stmt = select(Device.fcm_token).where(
            Device.user_id == user_id,
            Device.notifications_enabled.is_(True),
        )
        rows = (await self.db.execute(stmt)).all()
        return [r[0] for r in rows]
