"""Integration tests for admin notification endpoints."""

from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete

from app.db.session import AsyncSessionLocal
from app.models.user import User


async def _create_admin() -> tuple[User, str]:
    """Create an admin user directly in DB, return (user, email)."""
    email = f"admin-{uuid4().hex[:8]}@mindora.dev"
    async with AsyncSessionLocal() as db:
        user = User(
            email=email,
            hashed_password="not-used-for-test",
            full_name="Test Admin",
            is_admin=True,
            is_active=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user, email


async def _cleanup_user(email: str) -> None:
    async with AsyncSessionLocal() as db:
        await db.execute(delete(User).where(User.email == email))
        await db.commit()


@pytest.fixture
async def admin_token(client: AsyncClient) -> str:
    """Create admin + login to get a token."""
    user, email = await _create_admin()
    try:
        # Assume auth login works and returns tokens.access_token
        from app.core.security import hash_password

        # Set a real password so login works
        async with AsyncSessionLocal() as db:
            u = await db.get(User, user.id)
            u.hashed_password = hash_password("AdminPass123!")
            await db.commit()

        resp = await client.post(
            "/api/v1/auth/login",
            json={"email": email, "password": "AdminPass123!"},
        )
        assert resp.status_code == 200, resp.text
        data = resp.json()
        token = data["tokens"]["access_token"]
        yield token
    finally:
        await _cleanup_user(email)


@pytest.fixture
async def regular_token(client: AsyncClient) -> str:
    """Create regular user + login."""
    email = f"user-{uuid4().hex[:8]}@mindora.dev"
    async with AsyncSessionLocal() as db:
        from app.core.security import hash_password
        user = User(
            email=email,
            hashed_password=hash_password("UserPass123!"),
            full_name="Test User",
            is_admin=False,
            is_active=True,
        )
        db.add(user)
        await db.commit()

    try:
        resp = await client.post(
            "/api/v1/auth/login",
            json={"email": email, "password": "UserPass123!"},
        )
        assert resp.status_code == 200
        token = resp.json()["tokens"]["access_token"]
        yield token
    finally:
        await _cleanup_user(email)


# ---------------------------------------------------------------------------
# /admin/health
# ---------------------------------------------------------------------------


class TestAdminHealth:
    @pytest.mark.asyncio
    async def test_requires_auth(self, client: AsyncClient):
        r = await client.get("/api/v1/notifications/admin/health")
        assert r.status_code == 401

    @pytest.mark.asyncio
    async def test_requires_admin(
        self, client: AsyncClient, regular_token: str
    ):
        r = await client.get(
            "/api/v1/notifications/admin/health",
            headers={"Authorization": f"Bearer {regular_token}"},
        )
        assert r.status_code == 403

    @pytest.mark.asyncio
    async def test_returns_health(
        self, client: AsyncClient, admin_token: str
    ):
        r = await client.get(
            "/api/v1/notifications/admin/health",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 200
        data = r.json()
        assert "running" in data
        assert "job_count" in data
        assert "provider" in data
        assert "jobs" in data
        assert isinstance(data["jobs"], list)


# ---------------------------------------------------------------------------
# /admin/trigger-job/{job_id}
# ---------------------------------------------------------------------------


class TestAdminTriggerJob:
    @pytest.mark.asyncio
    async def test_requires_admin(
        self, client: AsyncClient, regular_token: str
    ):
        r = await client.post(
            "/api/v1/notifications/admin/trigger-job/notif_scan_upcoming_sessions",
            headers={"Authorization": f"Bearer {regular_token}"},
        )
        assert r.status_code == 403

    @pytest.mark.asyncio
    async def test_unknown_job_404(
        self, client: AsyncClient, admin_token: str
    ):
        r = await client.post(
            "/api/v1/notifications/admin/trigger-job/not_a_real_job",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 404

    @pytest.mark.asyncio
    async def test_trigger_upcoming_sessions(
        self, client: AsyncClient, admin_token: str
    ):
        r = await client.post(
            "/api/v1/notifications/admin/trigger-job/notif_scan_upcoming_sessions",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 200, r.text
        data = r.json()
        assert data["job_id"] == "notif_scan_upcoming_sessions"
        assert isinstance(data["processed"], int)
        assert data["processed"] >= 0
