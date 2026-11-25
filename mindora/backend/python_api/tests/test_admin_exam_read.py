"""Tests for LIVRABLE B8 — Admin reading student exams with mandatory justification."""
from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import delete, select

from app.core.security import create_access_token, hash_password
from app.db.session import AsyncSessionLocal
from app.models.audit_log import AuditLog
from app.models.exam_read_request import ExamReadRequest
from app.models.mock_exam import MOCK_STATUS_GRADED, MockAnswer, MockExam, MockQuestion
from app.models.user import User


async def _make_user(*, is_admin: bool) -> User:
    email = f"b8-{uuid4().hex[:8]}@mindora.dev"
    async with AsyncSessionLocal() as db:
        u = User(
            email=email,
            hashed_password=hash_password("B8Pass2026!"),
            full_name="B8 User",
            is_admin=is_admin,
            is_active=True,
            is_verified=True,
        )
        db.add(u)
        await db.commit()
        await db.refresh(u)
        return u


@pytest.mark.asyncio
async def test_b8_admin_must_provide_written_justification_to_read_student_exams(
    client: AsyncClient,
):
    admin = await _make_user(is_admin=True)
    student1 = await _make_user(is_admin=False)
    student2 = await _make_user(is_admin=False)

    async with AsyncSessionLocal() as db:
        ex1 = MockExam(
            user_id=student1.id,
            title="Bac Blanc Maths S1",
            subject="Mathematics",
            question_count=1,
            duration_minutes=60,
            status=MOCK_STATUS_GRADED,
            score=85.0,
        )
        ex2 = MockExam(
            user_id=student2.id,
            title="Bac Blanc Physique S2 (Other student)",
            subject="Physics",
            question_count=1,
            duration_minutes=60,
            status=MOCK_STATUS_GRADED,
            score=70.0,
        )
        db.add_all([ex1, ex2])
        await db.flush()
        q1 = MockQuestion(
            exam_id=ex1.id,
            position=1,
            question_type="mcq",
            prompt="2+2=?",
            options=[{"label": "A", "text": "4"}],
            correct_answer="A",
        )
        db.add(q1)
        await db.flush()
        db.add(
            MockAnswer(
                exam_id=ex1.id,
                question_id=q1.id,
                user_answer="A",
                is_correct=True,
                points_awarded=1,
            )
        )
        await db.commit()
        ex1_id = str(ex1.id)
        ex2_id = str(ex2.id)

    a_headers = {"Authorization": f"Bearer {create_access_token(subject=str(admin.id))}"}
    s_headers = {"Authorization": f"Bearer {create_access_token(subject=str(student1.id))}"}

    try:
        # 1. Student rejected (403)
        assert (
            await client.post(
                f"/api/v1/admin/students/{student1.id}/exams/read-request",
                headers=s_headers,
                json={"reason": "Assistance support ticket #42"},
            )
        ).status_code == 403

        # 2. Admin reading WITHOUT prior justification rejected (403)
        r_no_just = await client.get(
            f"/api/v1/admin/students/{student1.id}/exams",
            headers=a_headers,
        )
        assert r_no_just.status_code == 403

        # 3. Blank or too-short reason rejected (422)
        for bad_reason in ["", "   ", "short"]:
            r_bad = await client.post(
                f"/api/v1/admin/students/{student1.id}/exams/read-request",
                headers=a_headers,
                json={"reason": bad_reason},
            )
            assert r_bad.status_code == 422

        # 4. Valid written justification accepted (201)
        reason_text = "Vérification demandée par l'élève sur le ticket support #1042"
        r_req = await client.post(
            f"/api/v1/admin/students/{student1.id}/exams/read-request",
            headers=a_headers,
            json={"reason": reason_text},
        )
        assert r_req.status_code == 201, r_req.text
        req_id = r_req.json()["id"]

        # 5. Admin can now read ONLY student1's exams (not student2's)
        r_exams = await client.get(
            f"/api/v1/admin/students/{student1.id}/exams",
            headers=a_headers,
        )
        assert r_exams.status_code == 200, r_exams.text
        body = r_exams.json()
        assert body["student_id"] == str(student1.id)
        assert body["justification_request_id"] == req_id
        assert body["reason"] == reason_text
        returned_ids = {e["id"] for e in body["exams"]}
        assert ex1_id in returned_ids
        assert ex2_id not in returned_ids
        assert body["exams"][0]["answers"][0]["user_answer"] == "A"

        # 6. Student2 still blocked until separate justification
        assert (
            await client.get(
                f"/api/v1/admin/students/{student2.id}/exams",
                headers=a_headers,
            )
        ).status_code == 403

        # 7. Audit logs record both read_request and read
        async with AsyncSessionLocal() as db:
            logs = (
                await db.execute(
                    select(AuditLog).where(AuditLog.admin_id == admin.id)
                )
            ).scalars().all()
            actions = {l.action for l in logs}
            assert "student_exams.read_request" in actions
            assert "student_exams.read" in actions
    finally:
        async with AsyncSessionLocal() as db:
            await db.execute(
                delete(ExamReadRequest).where(ExamReadRequest.admin_id == admin.id)
            )
            await db.execute(delete(AuditLog).where(AuditLog.admin_id == admin.id))
            await db.execute(
                delete(User).where(User.id.in_([admin.id, student1.id, student2.id]))
            )
            await db.commit()
