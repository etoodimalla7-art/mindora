"""Tests for realtime notification hooks.

Hooks are NON-BLOCKING: they must never raise, even if the provider fails.
"""

from __future__ import annotations

from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch
from uuid import uuid4

import pytest

from app.services.notification import hooks as hooks_module


class TestOnSessionCompleted:
    @pytest.mark.asyncio
    async def test_runs_without_error(self, db_session, test_user, test_device):
        """Hook dispatches without raising."""

        class FakeSession:
            id = uuid4()
            subject = "Mathématiques"
            title = "Révisions Bac"
            completed_at = datetime.now(timezone.utc)

        # Should not raise
        await hooks_module.on_session_completed(
            db_session, user=test_user, session=FakeSession()
        )

    @pytest.mark.asyncio
    async def test_swallows_provider_errors(
        self, db_session, test_user, test_device
    ):
        """Even if provider raises, hook must not propagate."""
        with patch(
            "app.services.notification.hooks.get_notification_provider",
            side_effect=RuntimeError("provider exploded"),
        ):
            class FakeSession:
                id = uuid4()
                subject = "Test"
                title = "Test"
                completed_at = datetime.now(timezone.utc)

            # Must NOT raise
            await hooks_module.on_session_completed(
                db_session, user=test_user, session=FakeSession()
            )


class TestOnDocumentReady:
    @pytest.mark.asyncio
    async def test_runs_without_error(self, db_session, test_user, test_device):
        class FakeDoc:
            id = uuid4()
            title = "Cours de physique"
            filename = "physique.pdf"

        await hooks_module.on_document_ready(
            db_session, user=test_user, document=FakeDoc()
        )

    @pytest.mark.asyncio
    async def test_swallows_errors(self, db_session, test_user):
        with patch(
            "app.services.notification.hooks.get_notification_provider",
            side_effect=RuntimeError("boom"),
        ):
            class FakeDoc:
                id = uuid4()
                title = "X"
                filename = "x.pdf"

            await hooks_module.on_document_ready(
                db_session, user=test_user, document=FakeDoc()
            )


class TestOnMockExamGenerated:
    @pytest.mark.asyncio
    async def test_runs_without_error(self, db_session, test_user, test_device):
        class FakeMock:
            id = uuid4()
            subject = "Maths"
            title = "Mock #1"

        await hooks_module.on_mock_exam_generated(
            db_session, user=test_user, mock_exam=FakeMock()
        )

    @pytest.mark.asyncio
    async def test_swallows_errors(self, db_session, test_user):
        with patch(
            "app.services.notification.hooks.get_notification_provider",
            side_effect=RuntimeError("nope"),
        ):
            class FakeMock:
                id = uuid4()
                subject = "X"
                title = "Y"

            await hooks_module.on_mock_exam_generated(
                db_session, user=test_user, mock_exam=FakeMock()
            )
