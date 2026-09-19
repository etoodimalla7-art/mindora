"""Admin/moderation: the review queue, approve/reject, the
contribution-credit trigger, and the past-paper linking — the full
loop from Phase 16, over real HTTP."""


def _submit_exam_document(client, headers):
    from tests.conftest import make_valid_description, make_valid_pdf_bytes
    files = {"file": ("exam.pdf", make_valid_pdf_bytes(), "application/pdf")}
    doc_id = client.post("/api/v1/documents/upload", headers=headers, files=files).json()["data"]["id"]
    client.post(f"/api/v1/documents/{doc_id}/metadata", headers=headers, json={
        "title": "GCE Advanced Level Mathematics 2024", "description": make_valid_description("mathematics"),
        "category": "Mathematics", "level": "Advanced Level", "language": "en",
    })
    client.post(f"/api/v1/documents/{doc_id}/exam-metadata", headers=headers, json={
        "is_exam": True, "exam_system": "GCE", "exam_name": "GCE Advanced Level",
        "exam_level": "Advanced Level", "exam_subject": "Mathematics", "exam_year": 2024,
    })
    submit = client.post(f"/api/v1/documents/{doc_id}/submit", headers=headers)
    assert submit.status_code == 200, submit.text
    return doc_id


def test_document_appears_in_queue(registered_user, admin_user, client):
    doc_id = _submit_exam_document(client, registered_user["headers"])
    queue = client.get("/api/v1/admin/documents/queue", headers=admin_user["headers"])
    assert queue.status_code == 200
    assert any(item["id"] == doc_id for item in queue.json()["data"])


def test_approve_awards_no_bonus_below_threshold_and_creates_past_paper(registered_user, admin_user, client):
    doc_id = _submit_exam_document(client, registered_user["headers"])
    response = client.post(f"/api/v1/admin/documents/{doc_id}/approve", headers=admin_user["headers"])
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["status"] == "Approved"
    assert data["credits_awarded"] == 0  # 1st approval, threshold is 5
    assert data["past_paper_created"] is True


def test_double_approval_rejected(registered_user, admin_user, client):
    doc_id = _submit_exam_document(client, registered_user["headers"])
    client.post(f"/api/v1/admin/documents/{doc_id}/approve", headers=admin_user["headers"])
    second = client.post(f"/api/v1/admin/documents/{doc_id}/approve", headers=admin_user["headers"])
    assert second.status_code == 422


def test_reject_records_reason(registered_user, admin_user, client):
    doc_id = _submit_exam_document(client, registered_user["headers"])
    response = client.post(
        f"/api/v1/admin/documents/{doc_id}/reject", headers=admin_user["headers"],
        json={"reason": "Content does not match declared subject."},
    )
    assert response.status_code == 200
    assert response.json()["data"]["status"] == "Rejected"


def test_audit_log_records_approval(registered_user, admin_user, client):
    doc_id = _submit_exam_document(client, registered_user["headers"])
    client.post(f"/api/v1/admin/documents/{doc_id}/approve", headers=admin_user["headers"])

    audit = client.get("/api/v1/admin/audit-log", headers=admin_user["headers"])
    assert audit.status_code == 200
    entries = audit.json()["data"]
    assert any(e["action"] == "document_approved" and e["target_id"] == doc_id for e in entries)
