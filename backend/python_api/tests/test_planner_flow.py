"""End-to-end planner flow test."""
from __future__ import annotations

import uuid
from datetime import date, timedelta

import pytest


def _email() -> str:
    return f"planner_{uuid.uuid4().hex[:8]}@example.com"


@pytest.mark.asyncio
async def test_create_exam_plan_and_complete_session(client):
    # 1. Register
    email = _email()
    r = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "PlannerPass123!", "full_name": "Planner Tester",
              "preferred_language": "en", "country_code": "CM"},
    )
    assert r.status_code == 201, r.text
    access = r.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {access}"}

    # 2. Create exam plan
    target = (date.today() + timedelta(days=10)).isoformat()
    r = await client.post(
        "/api/v1/planner/exam",
        headers=headers,
        json={
            "exam_system": "GCE",
            "exam_level": "ADVANCED_LEVEL",
            "exam_name": "GCE A-Level",
            "subjects": ["Mathematics", "Physics"],
            "target_date": target,
            "daily_minutes": 90,
        },
    )
    assert r.status_code == 201, r.text
    plan = r.json()
    assert plan["plan_type"] == "exam"
    assert len(plan["sessions"]) > 0
    first_session_id = plan["sessions"][0]["id"]

    # 3. Complete the first session
    r = await client.post(
        f"/api/v1/planner/sessions/{first_session_id}/complete",
        headers=headers,
        json={"confidence_after": 0.7, "notes": "Went well"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "completed"

    # 4. Dashboard should reflect streak = 1
    r = await client.get("/api/v1/dashboard", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["streak_days"] == 1
    assert r.json()["exam_countdown"]["days_remaining"] == 10
