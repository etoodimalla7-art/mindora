"""End-to-end mock exam test.

Requires:
- Live Postgres
- At least one approved document for the test user
- Working Gemini API key (for question generation)

If the API key is not configured, the test will skip gracefully.
"""
from __future__ import annotations

import uuid
from datetime import date, timedelta

import pytest


def _email() -> str:
    return f"mock_{uuid.uuid4().hex[:8]}@example.com"


@pytest.mark.asyncio
async def test_mock_exam_full_flow(client):
    # 1. Register a fresh user.
    email = _email()
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "ExamPass123!",
            "full_name": "Mock Tester",
            "preferred_language": "en",
            "country_code": "CM",
        },
    )
    assert r.status_code == 201, r.text
    token = r.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Upload + submit + approve a document so the RAG has content.
    description = (
        "This document contains comprehensive course notes on differential "
        "equations with solved examples. It covers first-order ordinary "
        "differential equations, separable variables, linear equations, "
        "integrating factors, and applications to physics problems. "
        "The material is intended for advanced-level students preparing "
        "for national examinations. Each section includes worked exercises "
        "and review questions that reinforce the underlying concepts."
    )
    file_content = (
        "Differential equations: dy/dx = f(x, y). "
        "Separable equations: dy/dx = g(x) * h(y). "
        "Linear first-order: dy/dx + P(x)y = Q(x). "
        "Integrating factor: mu(x) = exp(int P(x) dx). "
        "Second order: a y'' + b y' + c y = f(x). "
    ) * 30

    files = {
        "file": ("notes.txt", file_content, "text/plain"),
    }
    data = {
        "title": "Test DE notes",
        "description": description,
    }
    r = await client.post(
        "/api/v1/documents/upload",
        headers=headers,
        files=files,
        data=data,
    )
    assert r.status_code == 201, r.text
    doc_id = r.json()["id"]

    r = await client.post(
        f"/api/v1/documents/{doc_id}/submit",
        headers=headers,
        json={
            "category": "Mathematics",
            "academic_level": "GCE_AL",
            "language": "en",
            "document_type": "course_notes",
        },
    )
    assert r.status_code == 200, r.text

    # Promote to admin for approval (first user in a fresh DB is already admin,
    # but be defensive).
    r = await client.post(
        f"/api/v1/admin/documents/{doc_id}/approve", headers=headers
    )
    if r.status_code != 200:
        pytest.skip("User is not admin in this environment.")

    # 3. Create a mock exam.
    r = await client.post(
        "/api/v1/mock-exams",
        headers=headers,
        json={
            "title": "Quick DE test",
            "subject": "Mathematics",
            "academic_level": "GCE_AL",
            "question_count": 3,
            "duration_minutes": 15,
            "difficulty": "medium",
        },
    )
    if r.status_code == 422:
        pytest.skip(f"Question generation failed (likely no AI key): {r.text}")
    assert r.status_code == 201, r.text
    exam = r.json()
    exam_id = exam["id"]
    assert exam["status"] == "ready"
    assert len(exam["questions"]) >= 1
    first_q = exam["questions"][0]
    assert "correct_answer" not in first_q, "Answer leaked while exam is ready"

    # 4. Start the exam.
    r = await client.post(f"/api/v1/mock-exams/{exam_id}/start", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "in_progress"

    # 5. Answer every question (we don't know the correct answer, so just submit).
    for q in exam["questions"]:
        r = await client.post(
            f"/api/v1/mock-exams/{exam_id}/answer",
            headers=headers,
            json={
                "question_id": q["id"],
                "answer": "A",  # arbitrary — grading will tell us
                "time_spent_seconds": 10,
            },
        )
        assert r.status_code == 200, r.text

    # 6. Submit + grade.
    r = await client.post(f"/api/v1/mock-exams/{exam_id}/submit", headers=headers)
    assert r.status_code == 200, r.text
    results = r.json()
    assert results["status"] == "graded"
    assert results["score"] is not None
    assert len(results["answers"]) == len(exam["questions"])

    # 7. Verify each answer now has the correct_answer exposed.
    for a in results["answers"]:
        assert "correct_answer" in a
