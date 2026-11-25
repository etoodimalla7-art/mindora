"""Tests for LIVRABLE B3 — App Settings + Feature Flags."""
from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete, select

from app.core.security import create_access_token, hash_password
from app.db.session import AsyncSessionLocal
from app.models.audit_log import AuditLog
from app.models.user import User


async def _create_user(*, is_admin: bool) -> User:
    email = f"b3-{uuid4().hex[:8]}@mindora.dev"
    async with AsyncSessionLocal() as db:
        u = User(
            email=email,
            hashed_password=hash_password("B3Pass2026!"),
            full_name="B3 User",
            is_admin=is_admin,
            is_active=True,
            is_verified=True,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)
        return u


@pytest.mark.asyncio
async def test_b3_public_and_admin_settings_and_feature_flags(client: AsyncClient):
    admin = await _create_user(is_admin=True)
    student = await _create_user(is_admin=False)
    admin_headers = {
        "Authorization": f"Bearer {create_access_token(subject=str(admin.id))}"
    }
    student_headers = {
        "Authorization": f"Bearer {create_access_token(subject=str(student.id))}"
    }

    try:
        # 1. Public settings must include public keys & omit private security keys
        r_pub = await client.get("/api/v1/settings/public")
        assert r_pub.status_code == 200, r_pub.text
        pub = r_pub.json()
        assert pub["settings"]["app.name"] == "MINDORA"
        assert "app.support_email" in pub["settings"]
        assert "security.max_login_attempts" not in pub["settings"]
        assert "offline_sync" in pub["flags"]

        # 2. Public feature flags
        r_flags = await client.get("/api/v1/feature-flags")
        assert r_flags.status_code == 200, r_flags.text
        flag_keys = {f["key"] for f in r_flags.json()}
        assert {"ai_chat", "flashcards", "streak_gamification", "offline_sync"} <= flag_keys

        # 3. Student forbidden on admin endpoints
        assert (
            await client.get("/api/v1/settings/admin", headers=student_headers)
        ).status_code == 403
        assert (
            await client.put(
                "/api/v1/settings/admin/app.support_email",
                headers=student_headers,
                json={"value": "hacked@mindora.dev"},
            )
        ).status_code == 403
        assert (
            await client.put(
                "/api/v1/feature-flags/offline_sync",
                headers=student_headers,
                json={"enabled": False},
            )
        ).status_code == 403

        # 4. Admin lists all settings (including private)
        r_admin_list = await client.get("/api/v1/settings/admin", headers=admin_headers)
        assert r_admin_list.status_code == 200, r_admin_list.text
        keys = {s["key"] for s in r_admin_list.json()}
        assert "security.max_login_attempts" in keys

        # 5. Admin updates setting -> verify & restore + verify AuditLog
        r_upd_set = await client.put(
            "/api/v1/settings/admin/app.support_email",
            headers=admin_headers,
            json={"value": "aide@mindora.dev"},
        )
        assert r_upd_set.status_code == 200, r_upd_set.text
        assert r_upd_set.json()["value"] == "aide@mindora.dev"

        r_restore_set = await client.put(
            "/api/v1/settings/admin/app.support_email",
            headers=admin_headers,
            json={"value": "support@mindora.dev"},
        )
        assert r_restore_set.status_code == 200

        # 6. Admin toggles feature flag -> verify & restore + verify AuditLog
        r_upd_flag = await client.put(
            "/api/v1/feature-flags/offline_sync",
            headers=admin_headers,
            json={"enabled": False, "rollout_percentage": 50},
        )
        assert r_upd_flag.status_code == 200, r_upd_flag.text
        assert r_upd_flag.json()["enabled"] is False
        assert r_upd_flag.json()["rollout_percentage"] == 50

        r_restore_flag = await client.put(
            "/api/v1/feature-flags/offline_sync",
            headers=admin_headers,
            json={"enabled": True, "rollout_percentage": 100},
        )
        assert r_restore_flag.status_code == 200

        async with AsyncSessionLocal() as db:
            logs = (
                await db.execute(
                    select(AuditLog).where(AuditLog.admin_id == admin.id)
                )
            ).scalars().all()
            actions = {entry.action for entry in logs}
            assert "settings.update" in actions
            assert "feature_flag.update" in actions
    finally:
        async with AsyncSessionLocal() as db:
            await db.execute(delete(AuditLog).where(AuditLog.admin_id == admin.id))
            await db.execute(delete(User).where(User.id.in_([admin.id, student.id])))
            await db.commit()
