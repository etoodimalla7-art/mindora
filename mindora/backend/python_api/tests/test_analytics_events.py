"""Tests for LIVRABLE B5 — Analytics Events (RGPD-safe telemetry)."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete

from app.core.security import create_access_token, hash_password
from app.db.session import AsyncSessionLocal
from app.models.analytics_event import AnalyticsEvent
from app.models.user import User


async def _make_user(*, is_admin: bool = False, created_days_ago: int = 0) -> User:
    email = f"b5-{uuid4().hex[:8]}@mindora.dev"
    created_at = datetime.now(timezone.utc) - timedelta(days=created_days_ago)
    async with AsyncSessionLocal() as db:
        u = User(
            email=email,
            hashed_password=hash_password("B5Pass2026!"),
            full_name="B5 User",
            is_admin=is_admin,
            is_active=True,
            is_verified=True,
            created_at=created_at,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)
        return u


@pytest.mark.asyncio
async def test_b5_analytics_events_rgpd_and_admin_dashboards(client: AsyncClient):
    student = await _make_user(is_admin=False, created_days_ago=10)
    admin = await _make_user(is_admin=True)

    s_headers = {"Authorization": f"Bearer {create_access_token(subject=str(student.id))}"}
    a_headers = {"Authorization": f"Bearer {create_access_token(subject=str(admin.id))}"}

    try:
        # 1. Valid event recorded
        r_ok = await client.post(
            "/api/v1/analytics/events",
            headers=s_headers,
            json={
                "event_type": "study_session_completed",
                "metadata": {"subject": "Mathematics", "duration_minutes": 45},
                "platform": "android",
                "app_version": "1.0.0",
            },
        )
        assert r_ok.status_code == 201, r_ok.text
        assert r_ok.json()["event_type"] == "study_session_completed"

        # 2. Unknown event_type rejected (422)
        r_bad_type = await client.post(
            "/api/v1/analytics/events",
            headers=s_headers,
            json={"event_type": "arbitrary_evil_event", "metadata": {}},
        )
        assert r_bad_type.status_code == 422

        # 3. RGPD forbidden keys rejected (conversation text / PII)
        for bad_meta in [
            {"conversation_text": "Bonjour tuteur..."},
            {"prompt": "Résous x^2=4"},
            {"nested": {"email": "leak@mindora.dev"}},
            {"note": "Contact user@example.com"},
        ]:
            r_rgpd = await client.post(
                "/api/v1/analytics/events",
                headers=s_headers,
                json={"event_type": "app_open", "metadata": bad_meta},
            )
            assert r_rgpd.status_code == 422, f"Expected 422 for {bad_meta}"

        # 4. Student blocked from admin analytics
        assert (
            await client.get("/api/v1/admin/analytics/overview", headers=s_headers)
        ).status_code == 403

        # 5. Admin overview shows event counts
        r_ov = await client.get("/api/v1/admin/analytics/overview", headers=a_headers)
        assert r_ov.status_code == 200, r_ov.text
        ov = r_ov.json()
        assert ov["events"]["total"] >= 1
        assert ov["events"]["by_type"].get("study_session_completed", 0) >= 1

        # 6. Admin retention returns cohorts + J1/J7/J30
        r_ret = await client.get("/api/v1/admin/analytics/retention", headers=a_headers)
        assert r_ret.status_code == 200, r_ret.text
        ret = r_ret.json()
        assert "cohorts" in ret
        assert "j1_retention" in ret
        assert "j7_retention" in ret
        assert "j30_retention" in ret
        assert ret["j7_retention"] > 0.0  # student created 10d ago logged event today

        # 7. Admin funnel returns monotonic stages
        r_fun = await client.get("/api/v1/admin/analytics/funnel", headers=a_headers)
        assert r_fun.status_code == 200, r_fun.text
        stages = r_fun.json()["stages"]
        assert len(stages) == 6
        counts = [s["count"] for s in stages]
        assert counts == sorted(counts, reverse=True)
    finally:
        async with AsyncSessionLocal() as db:
            await db.execute(
                delete(AnalyticsEvent).where(AnalyticsEvent.user_id == student.id)
            )
            await db.execute(delete(User).where(User.id.in_([student.id, admin.id])))
            await db.commit()
