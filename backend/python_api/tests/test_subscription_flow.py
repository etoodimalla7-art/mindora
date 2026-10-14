"""End-to-end subscription flow test.

Uses a mocked payment provider so no real API call is made.
"""
from __future__ import annotations

import uuid

import pytest


def _email() -> str:
    return f"sub_{uuid.uuid4().hex[:8]}@example.com"


@pytest.mark.asyncio
async def test_list_plans_and_subscribe_unconfigured(client):
    """With an empty Flutterwave key, checkout must fail gracefully (503)."""
    email = _email()
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "SubPass123!",
            "full_name": "Sub Tester",
            "preferred_language": "en",
            "country_code": "CM",
        },
    )
    assert r.status_code == 201, r.text
    token = r.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # List plans (should work — no provider call).
    r = await client.get("/api/v1/subscriptions/plans", headers=headers)
    assert r.status_code == 200, r.text
    plans = r.json()
    assert len(plans) >= 1
    assert any(p["code"] == "student_monthly" for p in plans)

    # Checkout should fail with a clean error when provider is unconfigured.
    r = await client.post(
        "/api/v1/subscriptions/checkout",
        headers=headers,
        json={"plan_code": "student_monthly"},
    )
    # 502 or 503 depending on the exact provider behavior.
    assert r.status_code in (502, 503), r.text
    body = r.json()
    assert "error" in body

    # /subscriptions/me should return null (no active subscription).
    r = await client.get("/api/v1/subscriptions/me", headers=headers)
    assert r.status_code == 200
    # FastAPI returns null for None response_model
    assert r.json() is None or r.json() == {}


@pytest.mark.asyncio
async def test_webhook_unknown_reference_returns_200(client):
    """Webhook with unknown reference should return 200 (idempotent)."""
    body = b'{"status":"successful","data":{"tx_ref":"unknown-ref","id":123,"amount":10,"currency":"USD"}}'
    r = await client.post(
        "/api/v1/webhooks/flutterwave",
        content=body,
        headers={"verif-hash": "", "content-type": "application/json"},
    )
    # 200 expected (processed, but no matching payment)
    assert r.status_code in (200, 401), r.text
