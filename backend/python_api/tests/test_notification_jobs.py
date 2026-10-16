"""Smoke tests for notification jobs.

These verify each job runs end-to-end against the real dev DB without
raising. They do NOT assert on counts (the dev DB may contain seed data).

Exact-count assertions live in test_notification_engine.py (isolated users).
"""

from __future__ import annotations

from datetime import datetime, timezone

import pytest

from app.db.session import AsyncSessionLocal
from app.services.notification import jobs as jobs_module

NOW = datetime(2026, 10, 15, 18, 0, tzinfo=timezone.utc)


class TestJobsSmoke:
    @pytest.mark.asyncio
    async def test_upcoming_sessions_runs(self):
        async with AsyncSessionLocal() as db:
            n = await jobs_module.job_scan_upcoming_sessions(db, now=NOW)
            assert isinstance(n, int)
            assert n >= 0

    @pytest.mark.asyncio
    async def test_exam_countdown_runs(self):
        async with AsyncSessionLocal() as db:
            n = await jobs_module.job_scan_exam_countdown(db, now=NOW)
            assert isinstance(n, int)
            assert n >= 0

    @pytest.mark.asyncio
    async def test_streaks_runs(self):
        async with AsyncSessionLocal() as db:
            n = await jobs_module.job_scan_streaks(db, now=NOW)
            assert isinstance(n, int)
            assert n >= 0

    @pytest.mark.asyncio
    async def test_inactivity_runs(self):
        async with AsyncSessionLocal() as db:
            n = await jobs_module.job_scan_inactivity(db, now=NOW)
            assert isinstance(n, int)
            assert n >= 0

    @pytest.mark.asyncio
    async def test_subscriptions_runs(self):
        async with AsyncSessionLocal() as db:
            n = await jobs_module.job_scan_subscriptions(db, now=NOW)
            assert isinstance(n, int)
            assert n >= 0
