"""Tests for LIVRABLE B2 — Notifications (F-13)."""
from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete

from app.core.security import create_access_token, hash_password
from app.db.session import AsyncSessionLocal
from app.integrations.notifications.provider import PushMessage, PushResult
from app.models.notification import (
    NOTIF_STATUS_SENT,
    NOTIF_STATUS_SKIPPED_DAILY_LIMIT,
    NOTIF_STATUS_SKIPPED_PREF,
    NOTIF_STATUS_SKIPPED_QUIET_HOURS,
    Notification,
    NotificationPreference,
    NotificationRule,
)
from app.models.user import User
from app.services.notification.engine import NotificationEngine
from app.services.notification.rules import NotificationIntent


class _RecordingProvider:
    name = "stub"

    def __init__(self) -> None:
        self.sent: list[PushMessage] = []

    async def send(self, message: PushMessage) -> PushResult:
        self.sent.append(message)
        return PushResult(success=True, message_id=f"msg-{len(self.sent)}")

    async def send_batch(self, messages: list[PushMessage]) -> list[PushResult]:
        return [await self.send(m) for m in messages]


@pytest.mark.asyncio
async def test_f13_preferences_status_rules_and_mark_read(client: AsyncClient):
    email = f"notif-f13-{uuid4().hex[:8]}@mindora.dev"
    async with AsyncSessionLocal() as db:
        user = User(
            email=email,
            hashed_password=hash_password("PassF13!2026"),
            full_name="F13 Student",
            is_active=True,
            is_verified=True,
        )
        db.add(user)
        await db.flush()
        n1 = Notification(
            user_id=user.id,
            type="session_reminder",
            title="Session 1",
            body="Body 1",
            status=NOTIF_STATUS_SENT,
        )
        n2 = Notification(
            user_id=user.id,
            type="streak",
            title="Streak 2",
            body="Body 2",
            status=NOTIF_STATUS_SENT,
        )
        db.add_all([n1, n2])
        await db.commit()
        user_id = user.id
        n1_id = str(n1.id)
        n2_id = str(n2.id)

    token = create_access_token(subject=str(user_id))
    headers = {"Authorization": f"Bearer {token}"}

    try:
        # 1. GET preferences -> default F-13 limits + push_blocked_reason
        r_prefs = await client.get("/api/v1/notifications/preferences", headers=headers)
        assert r_prefs.status_code == 200, r_prefs.text
        prefs_data = r_prefs.json()
        assert prefs_data["max_per_day"] == 3
        assert prefs_data["quiet_hours_start"] == 22
        assert prefs_data["quiet_hours_end"] == 7
        assert prefs_data["push_enabled"] is False
        assert prefs_data["push_blocked_reason"] == "BLOQUÉ PAR : clé Firebase"

        # 2. PUT preferences
        r_put = await client.put(
            "/api/v1/notifications/preferences",
            headers=headers,
            json={"max_per_day": 2, "quiet_hours_start": 21, "quiet_hours_end": 6},
        )
        assert r_put.status_code == 200, r_put.text
        assert r_put.json()["max_per_day"] == 2
        assert r_put.json()["quiet_hours_start"] == 21

        # 3. GET status & rules
        r_status = await client.get("/api/v1/notifications/status", headers=headers)
        assert r_status.status_code == 200
        assert r_status.json()["push_blocked_reason"] == "BLOQUÉ PAR : clé Firebase"

        r_rules = await client.get("/api/v1/notifications/rules", headers=headers)
        assert r_rules.status_code == 200
        rule_keys = {r["rule_key"] for r in r_rules.json()}
        assert "session_reminder" in rule_keys
        assert "exam_countdown" in rule_keys

        # 4. GET notifications + POST mark-read (single then all)
        r_list = await client.get("/api/v1/notifications", headers=headers)
        assert r_list.status_code == 200
        assert len(r_list.json()) == 2

        r_mark1 = await client.post(
            "/api/v1/notifications/mark-read",
            headers=headers,
            json={"notification_ids": [n1_id]},
        )
        assert r_mark1.status_code == 200
        assert r_mark1.json()["marked_count"] == 1

        r_mark_all = await client.post(
            "/api/v1/notifications/mark-read",
            headers=headers,
            json={},
        )
        assert r_mark_all.status_code == 200
        assert r_mark_all.json()["marked_count"] == 1

        r_list_after = await client.get("/api/v1/notifications", headers=headers)
        by_id = {item["id"]: item for item in r_list_after.json()}
        assert by_id[n1_id]["read_at"] is not None
        assert by_id[n2_id]["read_at"] is not None
    finally:
        async with AsyncSessionLocal() as db:
            await db.execute(delete(User).where(User.id == user_id))
            await db.commit()


@pytest.mark.asyncio
async def test_f13_engine_enforces_daily_limit_and_quiet_hours(
    db_session, test_user, test_device
):
    provider = _RecordingProvider()
    # 10:00 UTC == 11:00 Africa/Douala (outside 22h..7h quiet hours)
    daytime = datetime(2026, 11, 19, 10, 0, tzinfo=timezone.utc)
    engine = NotificationEngine(
        db_session,
        provider,
        locale="fr",
        enforce_quiet_hours=True,
        enforce_daily_limit=True,
        now_fn=lambda: daytime,
    )

    statuses = []
    for idx in range(4):
        intent = NotificationIntent(
            template_key="session_reminder",
            context={"user_name": "Amina", "subject_name": "Maths", "minutes": 15},
            priority=1,
            dedup_key=f"f13-limit:{idx}:{uuid4().hex[:6]}",
            user_id=str(test_user.id),
        )
        notif = await engine.dispatch_intent(intent)
        assert notif is not None
        statuses.append(notif.status)

    assert statuses[:3] == [NOTIF_STATUS_SENT, NOTIF_STATUS_SENT, NOTIF_STATUS_SENT]
    assert statuses[3] == NOTIF_STATUS_SKIPPED_DAILY_LIMIT
    assert len(provider.sent) == 3

    # Quiet hours: 22:30 UTC == 23:30 Africa/Douala (inside 22h..7h)
    nighttime = datetime(2026, 11, 19, 22, 30, tzinfo=timezone.utc)
    night_engine = NotificationEngine(
        db_session,
        provider,
        locale="fr",
        enforce_quiet_hours=True,
        enforce_daily_limit=False,
        now_fn=lambda: nighttime,
    )
    night_notif = await night_engine.dispatch_intent(
        NotificationIntent(
            template_key="streak",
            context={"user_name": "Amina", "streak_days": 4},
            priority=2,
            dedup_key=f"f13-quiet:{uuid4().hex[:6]}",
            user_id=str(test_user.id),
        )
    )
    assert night_notif is not None
    assert night_notif.status == NOTIF_STATUS_SKIPPED_QUIET_HOURS
    assert len(provider.sent) == 3
