"""Tests for LIVRABLE B7 — Admin Content CRUD (Subjects, Chapters, Announcements)."""
from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete, select

from app.core.security import create_access_token, hash_password
from app.db.session import AsyncSessionLocal
from app.models.audit_log import AuditLog
from app.models.curriculum import Announcement, Chapter, Subject
from app.models.user import User


async def _make_user(*, is_admin: bool) -> User:
    email = f"b7-{uuid4().hex[:8]}@mindora.dev"
    async with AsyncSessionLocal() as db:
        u = User(
            email=email,
            hashed_password=hash_password("B7Pass2026!"),
            full_name="B7 User",
            is_admin=is_admin,
            is_active=True,
            is_verified=True,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)
        return u


@pytest.mark.asyncio
async def test_b7_subjects_chapters_announcements_crud_soft_delete_and_audit(
    client: AsyncClient,
):
    admin = await _make_user(is_admin=True)
    student = await _make_user(is_admin=False)
    a_headers = {"Authorization": f"Bearer {create_access_token(subject=str(admin.id))}"}
    s_headers = {"Authorization": f"Bearer {create_access_token(subject=str(student.id))}"}

    subj_id = None
    chap_id = None
    ann_id = None

    try:
        slug = f"maths-{uuid4().hex[:6]}"
        # 1. Student denied
        assert (
            await client.post(
                "/api/v1/admin/subjects",
                headers=s_headers,
                json={"slug": slug, "name_fr": "Maths", "name_en": "Math"},
            )
        ).status_code == 403

        # 2. Subject CRUD + soft delete
        r_subj = await client.post(
            "/api/v1/admin/subjects",
            headers=a_headers,
            json={
                "slug": slug,
                "name_fr": "Mathématiques",
                "name_en": "Mathematics",
                "exam_systems": ["BAC", "GCE_A_LEVEL"],
                "display_order": 1,
            },
        )
        assert r_subj.status_code == 201, r_subj.text
        subj_id = r_subj.json()["id"]

        r_subj_upd = await client.put(
            f"/api/v1/admin/subjects/{subj_id}",
            headers=a_headers,
            json={"name_fr": "Mathématiques Avancées"},
        )
        assert r_subj_upd.status_code == 200
        assert r_subj_upd.json()["name_fr"] == "Mathématiques Avancées"

        # 3. Chapter CRUD + soft delete
        r_chap = await client.post(
            "/api/v1/admin/chapters",
            headers=a_headers,
            json={
                "subject_id": subj_id,
                "title_fr": "Nombres complexes",
                "title_en": "Complex Numbers",
                "level": "Terminale",
                "order_index": 1,
            },
        )
        assert r_chap.status_code == 201, r_chap.text
        chap_id = r_chap.json()["id"]

        r_chap_upd = await client.put(
            f"/api/v1/admin/chapters/{chap_id}",
            headers=a_headers,
            json={"title_en": "Complex Numbers & Geometry"},
        )
        assert r_chap_upd.status_code == 200
        assert r_chap_upd.json()["title_en"] == "Complex Numbers & Geometry"

        r_chap_del = await client.delete(
            f"/api/v1/admin/chapters/{chap_id}", headers=a_headers
        )
        assert r_chap_del.status_code == 200
        assert r_chap_del.json()["deleted_at"] is not None

        r_chap_list = await client.get(
            f"/api/v1/admin/chapters?subject_id={subj_id}", headers=a_headers
        )
        assert r_chap_list.status_code == 200
        assert all(c["id"] != chap_id for c in r_chap_list.json())

        # Soft-delete subject too
        r_subj_del = await client.delete(
            f"/api/v1/admin/subjects/{subj_id}", headers=a_headers
        )
        assert r_subj_del.status_code == 200
        assert r_subj_del.json()["deleted_at"] is not None

        # 4. Announcement CRUD + soft delete
        r_ann = await client.post(
            "/api/v1/admin/announcements",
            headers=a_headers,
            json={
                "title_fr": "Nouvelles annales 2025",
                "title_en": "New 2025 Past Papers",
                "body_fr": "Les sujets BAC & GCE sont en ligne.",
                "body_en": "BAC & GCE papers are now available.",
                "audience": "students",
                "priority": "normal",
            },
        )
        assert r_ann.status_code == 201, r_ann.text
        ann_id = r_ann.json()["id"]

        r_ann_upd = await client.put(
            f"/api/v1/admin/announcements/{ann_id}",
            headers=a_headers,
            json={"priority": "urgent"},
        )
        assert r_ann_upd.status_code == 200
        assert r_ann_upd.json()["priority"] == "urgent"

        r_ann_del = await client.delete(
            f"/api/v1/admin/announcements/{ann_id}", headers=a_headers
        )
        assert r_ann_del.status_code == 200
        assert r_ann_del.json()["deleted_at"] is not None

        r_ann_list = await client.get("/api/v1/admin/announcements", headers=a_headers)
        assert all(a["id"] != ann_id for a in r_ann_list.json())

        # 5. Audit logs verified for all 9 actions
        async with AsyncSessionLocal() as db:
            logs = (
                await db.execute(
                    select(AuditLog).where(AuditLog.admin_id == admin.id)
                )
            ).scalars().all()
            actions = {l.action for l in logs}
            assert {
                "subject.create",
                "subject.update",
                "subject.delete",
                "chapter.create",
                "chapter.update",
                "chapter.delete",
                "announcement.create",
                "announcement.update",
                "announcement.delete",
            } <= actions
    finally:
        async with AsyncSessionLocal() as db:
            if chap_id:
                await db.execute(delete(Chapter).where(Chapter.id == chap_id))
            if subj_id:
                await db.execute(delete(Subject).where(Subject.id == subj_id))
            if ann_id:
                await db.execute(delete(Announcement).where(Announcement.id == ann_id))
            await db.execute(delete(AuditLog).where(AuditLog.admin_id == admin.id))
            await db.execute(delete(User).where(User.id.in_([admin.id, student.id])))
            await db.commit()
