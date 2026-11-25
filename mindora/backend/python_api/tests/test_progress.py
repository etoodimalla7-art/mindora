"""Tests for LIVRABLE B6 — Student Progress (streak, heatmap, recommendation)."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete, select

from app.core.security import create_access_token, hash_password
from app.db.session import AsyncSessionLocal
from app.models.plan import StudyPlan, StudySession
from app.models.progress import TopicProgress, UserProgress
from app.models.user import User


@pytest.mark.asyncio
async def test_b6_streak_heatmap_and_recommendation(client: AsyncClient):
    email = f"b6-{uuid4().hex[:8]}@mindora.dev"
    now = datetime.now(timezone.utc)
    today = now.date()

    async with AsyncSessionLocal() as db:
        student = User(
            email=email,
            hashed_password=hash_password("B6Pass2026!"),
            full_name="B6 Student",
            is_active=True,
            is_verified=True,
        )
        db.add(student)
        await db.flush()

        plan = StudyPlan(
            user_id=student.id,
            title="Plan Maths BAC",
            plan_type="exam",
            subject="Mathematics",
            exam_system="BAC",
            start_date=today - timedelta(days=10),
            target_date=today + timedelta(days=30),
            daily_minutes=60,
            is_active=True,
        )
        db.add(plan)
        await db.flush()

        # Consecutive 3-day streak: today, -1d, -2d + isolated older day (-6d)
        for day_offset, mins in [(0, 45), (1, 30), (2, 60), (6, 25)]:
            ts = now - timedelta(days=day_offset)
            db.add(
                StudySession(
                    plan_id=plan.id,
                    user_id=student.id,
                    title=f"Session -{day_offset}d",
                    subject="Mathematics",
                    topic="Analyse",
                    scheduled_for=ts,
                    duration_minutes=mins,
                    status="completed",
                    completed_at=ts,
                )
            )

        db.add(
            TopicProgress(
                user_id=student.id,
                subject="Physics",
                topic="Électromagnétisme",
                mastery=0.35,
                confidence=0.40,
                questions_seen=10,
                questions_correct=4,
                minutes_studied=35,
            )
        )
        await db.commit()
        user_id = student.id

    headers = {"Authorization": f"Bearer {create_access_token(subject=str(user_id))}"}

    try:
        # 1. GET /progress/me computes streak=3 and persists user_progress row
        r_me = await client.get("/api/v1/progress/me", headers=headers)
        assert r_me.status_code == 200, r_me.text
        me = r_me.json()
        assert me["current_streak"] == 3
        assert me["longest_streak"] == 3
        assert me["sessions_completed"] == 4
        assert me["total_minutes"] >= 160
        assert me["total_xp"] == 100

        async with AsyncSessionLocal() as db:
            persisted = (
                await db.execute(
                    select(UserProgress).where(UserProgress.user_id == user_id)
                )
            ).scalar_one()
            assert persisted.current_streak == 3

        # 2. GET /progress/history?days=30 & 90
        r_h30 = await client.get("/api/v1/progress/history?days=30", headers=headers)
        assert r_h30.status_code == 200, r_h30.text
        h30 = r_h30.json()
        assert h30["days"] == 30
        assert len(h30["heatmap"]) == 30
        assert h30["active_days"] == 4
        assert h30["heatmap"][-1]["date"] == today.isoformat()
        assert h30["heatmap"][-1]["minutes"] == 45

        r_h90 = await client.get("/api/v1/progress/history?days=90", headers=headers)
        assert r_h90.status_code == 200
        assert len(r_h90.json()["heatmap"]) == 90

        # 3. GET /progress/recommendation targets weakest topic
        r_rec = await client.get("/api/v1/progress/recommendation", headers=headers)
        assert r_rec.status_code == 200, r_rec.text
        rec = r_rec.json()
        assert rec["action_type"] == "review_weak_topic"
        assert rec["subject"] == "Physics"
        assert rec["topic"] == "Électromagnétisme"
    finally:
        async with AsyncSessionLocal() as db:
            await db.execute(delete(User).where(User.id == user_id))
            await db.commit()
