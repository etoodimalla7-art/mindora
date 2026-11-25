"""End-to-end auth flow tests (requires live Postgres)."""
from __future__ import annotations

import uuid

import pytest


def _rand_email() -> str:
    return f"user_{uuid.uuid4().hex[:8]}@example.com"


@pytest.mark.asyncio
async def test_register_login_me_refresh_logout(client):
    email = _rand_email()
    password = "SuperSecret123!"

    # Register
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": password,
            "full_name": "Test Student",
            "preferred_language": "en",
            "country_code": "CM",
        },
    )
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["user"]["email"] == email

    # Login
    r = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": password},
    )
    assert r.status_code == 200, r.text
    access = r.json()["tokens"]["access_token"]
    refresh = r.json()["tokens"]["refresh_token"]

    # Me
    r = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {access}"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["email"] == email

    # Update education
    r = await client.put(
        "/api/v1/users/me/education",
        headers={"Authorization": f"Bearer {access}"},
        json={
            "education_system": "GCE",
            "level": "ADVANCED_LEVEL",
            "subjects": ["Mathematics", "Physics"],
            "goals": ["pass_gce_al"],
            "target_exam_date": "2027-06-15",
        },
    )
    assert r.status_code == 200, r.text
    assert r.json()["education_profile"]["education_system"] == "GCE"

    # Refresh
    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh})
    assert r.status_code == 200, r.text
    new_refresh = r.json()["tokens"]["refresh_token"]

    # Logout
    r = await client.post("/api/v1/auth/logout", json={"refresh_token": new_refresh})
    assert r.status_code == 204, r.text

    # Refresh after logout MUST fail
    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": new_refresh})
    assert r.status_code == 401, (
        f"Expected 401 after logout, got {r.status_code}: {r.text}"
    )


@pytest.mark.asyncio
async def test_login_wrong_password(client):
    email = _rand_email()
    await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "RightPass123!",
            "preferred_language": "en",
            "country_code": "CM",
        },
    )
    r = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "WrongPass123!"},
    )
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_register_duplicate_email(client):
    email = _rand_email()
    payload = {
        "email": email,
        "password": "Passw0rd!",
        "preferred_language": "en",
        "country_code": "CM",
    }
    r1 = await client.post("/api/v1/auth/register", json=payload)
    assert r1.status_code == 201
    r2 = await client.post("/api/v1/auth/register", json=payload)
    assert r2.status_code == 409
