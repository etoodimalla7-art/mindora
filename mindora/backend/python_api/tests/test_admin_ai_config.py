"""Tests for LIVRABLE B9 — Versioned AI Config, JSONB Snapshots, Rollback & AuditLog."""
from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete, select

from app.core.config import settings
from app.core.security import create_access_token, hash_password
from app.db.session import AsyncSessionLocal
from app.models.ai_config import AIConfig, AIConfigVersion
from app.models.audit_log import AuditLog
from app.models.user import User


async def _make_user(*, is_admin: bool) -> User:
    email = f"b9-{uuid4().hex[:8]}@mindora.dev"
    async with AsyncSessionLocal() as db:
        u = User(
            email=email,
            hashed_password=hash_password("B9Pass2026!"),
            full_name="B9 User",
            is_admin=is_admin,
            is_active=True,
            is_verified=True,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)
        return u


@pytest.mark.asyncio
async def test_b9_ai_config_versioning_snapshot_rollback_and_audit(
    client: AsyncClient,
    monkeypatch: pytest.MonkeyPatch,
):
    admin = await _make_user(is_admin=True)
    student = await _make_user(is_admin=False)
    a_headers = {"Authorization": f"Bearer {create_access_token(subject=str(admin.id))}"}
    s_headers = {"Authorization": f"Bearer {create_access_token(subject=str(student.id))}"}

    created_cfg_id = None
    created_version_ids: list = []
    orig_state: dict | None = None

    async with AsyncSessionLocal() as db:
        cfg = (
            await db.execute(select(AIConfig).where(AIConfig.is_active.is_(True)).limit(1))
        ).scalar_one_or_none()
        if cfg is None:
            cfg = AIConfig(
                name="default",
                system_prompt="You are MINDORA AI Tutor helping Cameroonian students succeed.",
                model="gemini-3.1-flash-lite",
                temperature=0.5,
                max_tokens=1200,
                language="fr",
                is_active=True,
                active_version=1,
            )
            db.add(cfg)
            await db.commit()
            await db.refresh(cfg)
            created_cfg_id = cfg.id
        else:
            orig_state = {
                "id": cfg.id,
                "system_prompt": cfg.system_prompt,
                "model": cfg.model,
                "temperature": cfg.temperature,
                "max_tokens": cfg.max_tokens,
                "language": cfg.language,
                "active_version": cfg.active_version,
                "updated_by": cfg.updated_by,
            }

    try:
        # 1. Student blocked (403)
        assert (
            await client.get("/api/v1/admin/ai/config", headers=s_headers)
        ).status_code == 403

        # 2. Without Gemini key -> BLOQUÉ PAR : clé Gemini
        monkeypatch.setattr(settings, "GEMINI_API_KEY", "")
        r_get = await client.get("/api/v1/admin/ai/config", headers=a_headers)
        assert r_get.status_code == 200, r_get.text
        cfg_json = r_get.json()
        assert cfg_json["ai_configured"] is False
        assert cfg_json["ai_blocked_reason"] == "BLOQUÉ PAR : clé Gemini"
        assert isinstance(cfg_json["active_version"], int)

        # 3. Update & publish first new version (vN+1)
        prompt_v1 = (
            "Tu es le tuteur pédagogique MINDORA spécialisé pour le Baccalauréat camerounais v1."
        )
        r_upd1 = await client.put(
            "/api/v1/admin/ai/config",
            headers=a_headers,
            json={
                "system_prompt": prompt_v1,
                "model": "gemini-2.5-flash",
                "temperature": 0.35,
                "max_tokens": 1500,
                "language": "fr",
            },
        )
        assert r_upd1.status_code == 200, r_upd1.text
        assert r_upd1.json()["system_prompt"] == prompt_v1

        r_pub1 = await client.post(
            "/api/v1/admin/ai/config/publish",
            headers=a_headers,
            json={"notes": "B9 snapshot v1"},
        )
        assert r_pub1.status_code == 200, r_pub1.text
        v1 = r_pub1.json()
        created_version_ids.append(v1["id"])
        assert v1["snapshot"]["system_prompt"] == prompt_v1
        assert v1["snapshot"]["model"] == "gemini-2.5-flash"
        assert v1["snapshot"]["temperature"] == pytest.approx(0.35)
        assert v1["snapshot"]["max_tokens"] == 1500
        assert v1["snapshot"]["language"] == "fr"

        # 4. Update & publish second version (vN+2)
        prompt_v2 = (
            "You are the MINDORA GCE A-Level & HND English tutor edition v2 with concise steps."
        )
        r_upd2 = await client.put(
            "/api/v1/admin/ai/config",
            headers=a_headers,
            json={
                "system_prompt": prompt_v2,
                "model": "gemini-3.1-flash-lite",
                "temperature": 0.75,
                "max_tokens": 2000,
                "language": "en",
            },
        )
        assert r_upd2.status_code == 200, r_upd2.text

        r_pub2 = await client.post(
            "/api/v1/admin/ai/config/publish",
            headers=a_headers,
            json={"notes": "B9 snapshot v2"},
        )
        assert r_pub2.status_code == 200, r_pub2.text
        v2 = r_pub2.json()
        created_version_ids.append(v2["id"])
        assert v2["version"] == v1["version"] + 1

        # Confirm active_version is now v2
        r_after_v2 = await client.get("/api/v1/admin/ai/config", headers=a_headers)
        assert r_after_v2.status_code == 200
        assert r_after_v2.json()["active_version"] == v2["version"]
        assert r_after_v2.json()["system_prompt"] == prompt_v2

        # 5. Rollback to v1 via /config/{id}/activate
        r_rb = await client.post(
            f"/api/v1/admin/ai/config/{v1['id']}/activate",
            headers=a_headers,
        )
        assert r_rb.status_code == 200, r_rb.text
        rb_json = r_rb.json()
        assert rb_json["active_version"] == v1["version"]
        assert rb_json["system_prompt"] == prompt_v1
        assert rb_json["model"] == "gemini-2.5-flash"
        assert rb_json["temperature"] == pytest.approx(0.35)
        assert rb_json["max_tokens"] == 1500
        assert rb_json["language"] == "fr"

        # 6. Verify version list & audit logs
        r_list = await client.get("/api/v1/admin/ai/versions", headers=a_headers)
        assert r_list.status_code == 200
        version_ids = {item["id"] for item in r_list.json()}
        assert v1["id"] in version_ids and v2["id"] in version_ids

        async with AsyncSessionLocal() as db:
            logs = (
                await db.execute(select(AuditLog).where(AuditLog.admin_id == admin.id))
            ).scalars().all()
            actions = {l.action for l in logs}
            assert {"ai_config.update", "ai_config.publish", "ai_config.rollback"} <= actions
    finally:
        async with AsyncSessionLocal() as db:
            for vid in created_version_ids:
                await db.execute(
                    delete(AIConfigVersion).where(AIConfigVersion.id == vid)
                )
            if created_cfg_id is not None:
                await db.execute(delete(AIConfig).where(AIConfig.id == created_cfg_id))
            elif orig_state is not None:
                cfg_row = await db.get(AIConfig, orig_state["id"])
                if cfg_row:
                    cfg_row.system_prompt = orig_state["system_prompt"]
                    cfg_row.model = orig_state["model"]
                    cfg_row.temperature = orig_state["temperature"]
                    cfg_row.max_tokens = orig_state["max_tokens"]
                    cfg_row.language = orig_state["language"]
                    cfg_row.active_version = orig_state["active_version"]
                    cfg_row.updated_by = orig_state["updated_by"]
            await db.execute(delete(AuditLog).where(AuditLog.admin_id == admin.id))
            await db.execute(delete(User).where(User.id.in_([admin.id, student.id])))
            await db.commit()
