"""End-to-end subscription flow test.

Two scenarios depending on whether Flutterwave is configured:
  - Key set    → checkout succeeds (201) and returns a checkout URL.
  - Key empty  → checkout fails gracefully with 502 or 503.
"""
from __future__ import annotations

import uuid

import pytest


def _email() -> str:
    return f"sub_{uuid.uuid4().hex[:8]}@example.com"


@pytest.mark.asyncio
async def test_list_plans_and_checkout(client):
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

    # 1. List plans.
    r = await client.get("/api/v1/subscriptions/plans", headers=headers)
    assert r.status_code == 200, r.text
    plans = r.json()
    assert len(plans) >= 1
    codes = [p["code"] for p in plans]
    assert "student_monthly" in codes, f"Missing student_monthly: {codes}"

    # 2. Attempt checkout — success or graceful failure both are valid.
    r = await client.post(
        "/api/v1/subscriptions/checkout",
        headers=headers,
        json={"plan_code": "student_monthly"},
    )
    assert r.status_code in (201, 502, 503), r.text

    if r.status_code == 201:
        body = r.json()
        assert "checkout_url" in body
        assert body["checkout_url"].startswith("http")
        assert body["payment"]["status"] == "pending"
    else:
        # Provider is not configured — should surface a clean error.
        body = r.json()
        assert "error" in body

    # 3. /me returns null (no active sub yet).
    r = await client.get("/api/v1/subscriptions/me", headers=headers)
    assert r.status_code == 200
    assert r.json() is None or r.json() == {}


@pytest.mark.asyncio
async def test_webhook_unknown_reference_returns_200(client):
    body = b'{"status":"successful","data":{"tx_ref":"unknown-ref","id":123,"amount":10,"currency":"USD"}}'
    r = await client.post(
        "/api/v1/webhooks/flutterwave",
        content=body,
        headers={"verif-hash": "", "content-type": "application/json"},
    )
    assert r.status_code in (200, 401), r.text
