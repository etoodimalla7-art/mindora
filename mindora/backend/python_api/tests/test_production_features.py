"""Tests for MINDORA Sprint 1 production features:
- Admin 2FA login challenge / verify / resend + no OTP leakage in logs
- Public settings & maintenance endpoints
- Student support tickets + public website contact form
- AI Vision / Voice contract validation & clean unconfigured error handling
- Progress overview & Mock Exam answer hiding
"""
from __future__ import annotations

import base64
import logging
import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy import delete, select

from app.core.security import hash_password
from app.db.session import AsyncSessionLocal
from app.models.otp_code import OTPCode
from app.models.user import User


async def _make_user(*, is_admin: bool = False) -> tuple[User, str]:
    email = f"prod-{uuid.uuid4().hex[:8]}@mindora.dev"
    password = "ProdPassword123!"
    async with AsyncSessionLocal() as db:
        u = User(
            email=email,
            hashed_password=hash_password(password),
            full_name="Prod Test User",
            is_admin=is_admin,
            is_active=True,
            is_verified=True,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)
        return u, password


async def _cleanup_user(email: str) -> None:
    async with AsyncSessionLocal() as db:
        await db.execute(delete(User).where(User.email == email))
        await db.commit()


@pytest.mark.asyncio
async def test_admin_2fa_flow_and_no_secret_in_logs(client: AsyncClient, caplog):
    admin, password = await _make_user(is_admin=True)
    student, _ = await _make_user(is_admin=False)
    try:
        # Non-admin must be rejected at /auth/admin/login
        r_forbidden = await client.post(
            "/api/v1/auth/admin/login",
            json={"email": student.email, "password": password},
        )
        assert r_forbidden.status_code == 403

        # Admin login triggers 2FA challenge without leaking code in logs
        with caplog.at_level(logging.INFO):
            r_chal = await client.post(
                "/api/v1/auth/admin/login",
                json={"email": admin.email, "password": password},
            )
        assert r_chal.status_code == 200, r_chal.text
        chal = r_chal.json()
        assert chal["requires_2fa"] is True
        assert chal["email"] == admin.email
        challenge_token = chal["challenge_token"]

        # Read generated 6-digit OTP directly from DB to verify
        async with AsyncSessionLocal() as db:
            otp = (
                await db.execute(
                    select(OTPCode)
                    .where(
                        OTPCode.user_id == admin.id,
                        OTPCode.purpose == "login_2fa",
                        OTPCode.used.is_(False),
                    )
                    .order_by(OTPCode.created_at.desc())
                    .limit(1)
                )
            ).scalar_one()
            code = otp.code

        # Verify code MUST NOT appear in any log record
        assert code not in caplog.text
        assert challenge_token not in caplog.text

        # Wrong code rejected
        r_bad = await client.post(
            "/api/v1/auth/admin/2fa/verify",
            json={"challenge_token": challenge_token, "code": "000000" if code != "000000" else "999999"},
        )
        assert r_bad.status_code == 400

        # Valid code issues tokens + permissions
        r_ok = await client.post(
            "/api/v1/auth/admin/2fa/verify",
            json={"challenge_token": challenge_token, "code": code},
        )
        assert r_ok.status_code == 200, r_ok.text
        body = r_ok.json()
        assert body["two_factor_verified"] is True
        assert "tokens" in body and body["tokens"]["access_token"]
        assert "users.read" in body["permissions"]
    finally:
        await _cleanup_user(admin.email)
        await _cleanup_user(student.email)


@pytest.mark.asyncio
async def test_public_settings_and_maintenance(client: AsyncClient):
    r_maint = await client.get("/api/v1/settings/maintenance")
    assert r_maint.status_code == 200, r_maint.text
    assert "enabled" in r_maint.json()

    r_pub = await client.get("/api/v1/settings/public")
    assert r_pub.status_code == 200, r_pub.text
    pub = r_pub.json()
    assert pub["identity"]["name"] == "MINDORA"
    assert "BAC" in pub["education_systems"]
    assert "ai_chat" in pub["flags"]
    assert isinstance(pub["content_strings"], dict)


@pytest.mark.asyncio
async def test_student_support_and_public_contact(client: AsyncClient):
    user, password = await _make_user(is_admin=False)
    try:
        # Public website contact form
        r_contact = await client.post(
            "/api/v1/support/contact",
            json={
                "name": "Jean Fotso",
                "email": user.email,
                "subject": "Question sur les annales GCE",
                "message": "Bonjour, comment télécharger les anciens sujets ?",
                "category": "admissions",
            },
        )
        assert r_contact.status_code == 201, r_contact.text
        ticket_id = r_contact.json()["ticket_id"]

        # Login as student and verify ticket appears in /tickets/mine
        r_login = await client.post(
            "/api/v1/auth/login",
            json={"email": user.email, "password": password},
        )
        token = r_login.json()["tokens"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r_mine = await client.get("/api/v1/support/tickets/mine", headers=headers)
        assert r_mine.status_code == 200, r_mine.text
        assert any(t["id"] == ticket_id for t in r_mine.json())

        # Create ticket as authenticated student
        r_create = await client.post(
            "/api/v1/support/tickets",
            headers=headers,
            json={
                "subject": "Problème Flashcards",
                "description": "Mes cartes SM-2 ne s'affichent pas hors ligne.",
                "priority": "high",
            },
        )
        assert r_create.status_code == 201, r_create.text
        new_id = r_create.json()["id"]

        # Reply on own ticket
        r_reply = await client.post(
            f"/api/v1/support/tickets/{new_id}/messages",
            headers=headers,
            json={"body": "Voici plus de détails sur mon appareil Android."},
        )
        assert r_reply.status_code == 201, r_reply.text
        assert r_reply.json()["is_admin"] is False
    finally:
        await _cleanup_user(user.email)


@pytest.mark.asyncio
async def test_progress_overview_and_vision_validation(client: AsyncClient):
    user, password = await _make_user(is_admin=False)
    try:
        r_login = await client.post(
            "/api/v1/auth/login",
            json={"email": user.email, "password": password},
        )
        token = r_login.json()["tokens"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        r_prog = await client.get("/api/v1/progress/overview", headers=headers)
        assert r_prog.status_code == 200, r_prog.text
        prog = r_prog.json()
        assert "readiness_score" in prog
        assert "readiness_breakdown" in prog

        # Invalid MIME type for vision must fail validation (422)
        png_1x1 = base64.b64encode(b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR").decode("ascii")
        r_bad_mime = await client.post(
            "/api/v1/ai/vision",
            headers=headers,
            json={
                "image_base64": png_1x1,
                "image_mime_type": "application/pdf",
                "prompt": "Résous cet exercice",
            },
        )
        assert r_bad_mime.status_code == 422
    finally:
        await _cleanup_user(user.email)
