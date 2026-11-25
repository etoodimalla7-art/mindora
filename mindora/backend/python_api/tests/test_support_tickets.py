"""Tests for LIVRABLE B4 — Support Tickets."""
from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete

from app.core.security import create_access_token, hash_password
from app.db.session import AsyncSessionLocal
from app.models.user import User


async def _make_user(*, is_admin: bool = False) -> User:
    email = f"b4-{uuid4().hex[:8]}@mindora.dev"
    async with AsyncSessionLocal() as db:
        u = User(
            email=email,
            hashed_password=hash_password("B4Pass2026!"),
            full_name="B4 User",
            is_admin=is_admin,
            is_active=True,
            is_verified=True,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)
        return u


@pytest.mark.asyncio
async def test_b4_support_ticket_full_lifecycle(client: AsyncClient):
    student1 = await _make_user(is_admin=False)
    student2 = await _make_user(is_admin=False)
    admin = await _make_user(is_admin=True)

    s1_headers = {"Authorization": f"Bearer {create_access_token(subject=str(student1.id))}"}
    s2_headers = {"Authorization": f"Bearer {create_access_token(subject=str(student2.id))}"}
    admin_headers = {"Authorization": f"Bearer {create_access_token(subject=str(admin.id))}"}

    try:
        # 1. Student creates ticket with category
        r_create = await client.post(
            "/api/v1/support/tickets",
            headers=s1_headers,
            json={
                "subject": "Problème paiement Mobile Money",
                "description": "La transaction MTN n'a pas activé mon pass.",
                "priority": "high",
                "category": "billing",
            },
        )
        assert r_create.status_code == 201, r_create.text
        created = r_create.json()
        assert created["category"] == "billing"
        assert created["status"] == "open"
        ticket_id = created["id"]

        # 2. Listed on both GET /support/tickets and GET /support/tickets/mine
        r_list = await client.get("/api/v1/support/tickets", headers=s1_headers)
        assert r_list.status_code == 200
        assert any(t["id"] == ticket_id for t in r_list.json())

        # 3. Other student forbidden (403)
        r_other = await client.get(
            f"/api/v1/support/tickets/{ticket_id}", headers=s2_headers
        )
        assert r_other.status_code == 403

        # 4. Student posts message
        r_msg = await client.post(
            f"/api/v1/support/tickets/{ticket_id}/messages",
            headers=s1_headers,
            json={"body": "Référence TX-9821"},
        )
        assert r_msg.status_code == 201
        assert r_msg.json()["is_admin"] is False

        # 5. Admin lists, assigns, replies
        r_admin_list = await client.get(
            "/api/v1/admin/support/tickets", headers=admin_headers
        )
        assert r_admin_list.status_code == 200
        assert any(t["id"] == ticket_id for t in r_admin_list.json()["items"])

        r_assign = await client.patch(
            f"/api/v1/admin/support/tickets/{ticket_id}/assign",
            headers=admin_headers,
            json={"assigned_to": str(admin.id)},
        )
        assert r_assign.status_code == 200
        assert r_assign.json()["assigned_to"] == str(admin.id)

        r_admin_reply = await client.post(
            f"/api/v1/admin/support/tickets/{ticket_id}/messages",
            headers=admin_headers,
            json={"body": "Votre pass a été activé manuellement."},
        )
        assert r_admin_reply.status_code == 201
        assert r_admin_reply.json()["is_admin"] is True

        # 6. Admin marks resolved then closed
        r_resolved = await client.patch(
            f"/api/v1/admin/support/tickets/{ticket_id}/status",
            headers=admin_headers,
            json={"status": "resolved"},
        )
        assert r_resolved.status_code == 200
        assert r_resolved.json()["resolved_at"] is not None

        r_closed = await client.patch(
            f"/api/v1/admin/support/tickets/{ticket_id}/status",
            headers=admin_headers,
            json={"status": "closed"},
        )
        assert r_closed.status_code == 200
        assert r_closed.json()["closed_at"] is not None

        # 7. Cannot reply to closed ticket
        r_closed_reply = await client.post(
            f"/api/v1/support/tickets/{ticket_id}/messages",
            headers=s1_headers,
            json={"body": "Merci !"},
        )
        assert r_closed_reply.status_code in (400, 422)

        # 8. Student detail shows messages
        r_detail = await client.get(
            f"/api/v1/support/tickets/{ticket_id}", headers=s1_headers
        )
        assert r_detail.status_code == 200
        assert len(r_detail.json()["messages"]) == 2
    finally:
        async with AsyncSessionLocal() as db:
            await db.execute(
                delete(User).where(User.id.in_([student1.id, student2.id, admin.id]))
            )
            await db.commit()
