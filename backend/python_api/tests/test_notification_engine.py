"""Tests for NotificationEngine.

Uses an in-memory SQLite? No — uses the real async engine via AsyncSessionLocal
with a rollback-per-test strategy. To avoid polluting the dev DB, each test
creates a unique user_id UUID and rolls back at the end via context manager.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

import pytest
import pytest_asyncio
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import AsyncSessionLocal
from app.integrations.notifications.provider import (
    NotificationProvider,
    PushMessage,
    PushResult,
)
from app.models.notification import (
    NOTIF_STATUS_FAILED,
    NOTIF_STATUS_NO_DEVICE,
    NOTIF_STATUS_SENT,
    NOTIF_STATUS_SKIPPED_DUPLICATE,
    NOTIF_STATUS_SKIPPED_PREF,
    Device,
    Notification,
    NotificationPreference,
)
from app.models.user import User
from app.services.notification.engine import NotificationEngine
from app.services.notification.rules import NotificationIntent


# ---------------------------------------------------------------------------
# Stub provider (no HTTP — captures what was sent)
# ---------------------------------------------------------------------------


class StubProvider:
    name = "stub"

    def __init__(self, *, succeed: bool = True) -> None:
        self.succeed = succeed
        self.sent: list[PushMessage] = []

    async def send(self, message: PushMessage) -> PushResult:
        self.sent.append(message)
        return PushResult(
            success=self.succeed,
            message_id="stub-" + message.token[:8],
            error=None if self.succeed else "stub failure",
        )

    async def send_batch(self, messages: list[PushMessage]) -> list[PushResult]:
        return [await self.send(m) for m in messages]


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest_asyncio.fixture
async def db_session() -> AsyncSession:
    """Real async DB session, cleaned up after the test."""
    async with AsyncSessionLocal() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> User:
    """Create a throwaway user, delete after test."""
    email = f"test-{uuid4().hex[:8]}@mindora.dev"
    user = User(
        email=email,
        hashed_password="not-used",
        full_name="Test User",
        is_admin=False,
    )
    # Some models require extra fields — adapt to your User model
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    yield user
    # cleanup: cascades through FK on user_id
    await db_session.execute(delete(User).where(User.id == user.id))
    await db_session.commit()


@pytest_asyncio.fixture
async def test_device(db_session: AsyncSession, test_user: User) -> Device:
    device = Device(
        user_id=test_user.id,
        fcm_token=f"token-{uuid4().hex[:16]}",
        platform="android",
        notifications_enabled=True,
    )
    db_session.add(device)
    await db_session.commit()
    await db_session.refresh(device)
    return device


def make_intent(user_id: UUID, template_key: str = "session_reminder") -> NotificationIntent:
    return NotificationIntent(
        template_key=template_key,
        context={
            "user_name": "Alice",
            "subject_name": "Maths",
            "minutes": 15,
            "streak_days": 5,
        },
        priority=1,
        dedup_key=f"{template_key}:{uuid4().hex[:8]}",
        user_id=str(user_id),
    )


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestDispatchIntent:
    @pytest.mark.asyncio
    async def test_sends_and_persists(self, db_session, test_user, test_device):
        provider = StubProvider(succeed=True)
        engine = NotificationEngine(
            db_session, provider, locale="fr", enforce_quiet_hours=False
        )
        intent = make_intent(test_user.id)

        notif = await engine.dispatch_intent(intent)

        assert notif is not None
        assert notif.status == NOTIF_STATUS_SENT
        assert notif.sent_at is not None
        assert notif.dedup_key == intent.dedup_key
        assert notif.template_key == "session_reminder"
        assert notif.priority == 1
        assert len(provider.sent) == 1
        assert "Alice" in provider.sent[0].title

    @pytest.mark.asyncio
    async def test_no_device(self, db_session, test_user):
        provider = StubProvider(succeed=True)
        engine = NotificationEngine(
            db_session, provider, locale="fr", enforce_quiet_hours=False
        )
        notif = await engine.dispatch_intent(make_intent(test_user.id))

        assert notif is not None
        assert notif.status == NOTIF_STATUS_NO_DEVICE
        assert len(provider.sent) == 0

    @pytest.mark.asyncio
    async def test_provider_failure_marks_failed(
        self, db_session, test_user, test_device
    ):
        provider = StubProvider(succeed=False)
        engine = NotificationEngine(
            db_session, provider, locale="fr", enforce_quiet_hours=False
        )
        notif = await engine.dispatch_intent(make_intent(test_user.id))

        assert notif is not None
        assert notif.status == NOTIF_STATUS_FAILED
        assert notif.sent_at is None

    @pytest.mark.asyncio
    async def test_duplicate_skipped(self, db_session, test_user, test_device):
        provider = StubProvider(succeed=True)
        engine = NotificationEngine(
            db_session, provider, locale="fr", enforce_quiet_hours=False
        )
        intent = make_intent(test_user.id)

        first = await engine.dispatch_intent(intent)
        assert first is not None
        await db_session.commit()

        second = await engine.dispatch_intent(intent)
        assert second is None  # dedup
        assert len(provider.sent) == 1  # only the first

    @pytest.mark.asyncio
    async def test_opt_out_skips(self, db_session, test_user, test_device):
        # Create prefs with session_reminders disabled
        prefs = NotificationPreference(
            user_id=test_user.id,
            enabled=True,
            session_reminders=False,
        )
        db_session.add(prefs)
        await db_session.commit()

        provider = StubProvider(succeed=True)
        engine = NotificationEngine(
            db_session, provider, locale="fr", enforce_quiet_hours=False
        )
        notif = await engine.dispatch_intent(make_intent(test_user.id))

        assert notif is not None
        assert notif.status == NOTIF_STATUS_SKIPPED_PREF
        assert len(provider.sent) == 0

    @pytest.mark.asyncio
    async def test_global_opt_out_skips(self, db_session, test_user, test_device):
        prefs = NotificationPreference(user_id=test_user.id, enabled=False)
        db_session.add(prefs)
        await db_session.commit()

        provider = StubProvider(succeed=True)
        engine = NotificationEngine(
            db_session, provider, locale="fr", enforce_quiet_hours=False
        )
        notif = await engine.dispatch_intent(make_intent(test_user.id))
        assert notif is not None
        assert notif.status == NOTIF_STATUS_SKIPPED_PREF

    @pytest.mark.asyncio
    async def test_locale_en(self, db_session, test_user, test_device):
        provider = StubProvider(succeed=True)
        engine = NotificationEngine(
            db_session, provider, locale="en", enforce_quiet_hours=False
        )
        await engine.dispatch_intent(make_intent(test_user.id))
        assert "Time to study" in provider.sent[0].title


class TestDispatchIntents:
    @pytest.mark.asyncio
    async def test_sorts_by_priority(self, db_session, test_user, test_device):
        provider = StubProvider(succeed=True)
        engine = NotificationEngine(
            db_session, provider, locale="fr", enforce_quiet_hours=False
        )

        low = make_intent(test_user.id, "inactivity")
        low = NotificationIntent(
            template_key="inactivity",
            context={"user_name": "Alice", "plan_name": "Bac"},
            priority=3,
            dedup_key=f"low:{uuid4().hex[:8]}",
            user_id=str(test_user.id),
        )
        high = make_intent(test_user.id, "session_reminder")

        await engine.dispatch_intents([low, high])

        # Both dispatched
        assert len(provider.sent) == 2
        # High priority rendered first (session_reminder title appears first)
        assert "C'est l'heure" in provider.sent[0].title
