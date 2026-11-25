"""Health endpoint tests."""
from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_liveness(client):
    r = await client.get("/api/v1/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert "app" in body and "version" in body


@pytest.mark.asyncio
async def test_root(client):
    r = await client.get("/")
    assert r.status_code == 200
    body = r.json()
    assert body["api"] == "/api/v1"


@pytest.mark.asyncio
async def test_request_id_header_present(client):
    r = await client.get("/api/v1/health")
    assert "x-request-id" in {k.lower() for k in r.headers}
