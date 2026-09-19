"""Document upload/metadata/submission, including the Phase 5 analysis
pipeline's honest-error paths."""


def _upload(client, headers, content=b"%PDF-1.4 fake pdf", filename="notes.pdf"):
    files = {"file": (filename, content, "application/pdf")}
    return client.post("/api/v1/documents/upload", headers=headers, files=files)


def test_upload_then_list_mine(registered_user, client):
    headers = registered_user["headers"]
    upload = _upload(client, headers)
    assert upload.status_code == 200
    assert upload.json()["data"]["status"] == "Draft"

    mine = client.get("/api/v1/documents/mine", headers=headers)
    assert mine.status_code == 200
    assert len(mine.json()["data"]) == 1


def test_upload_rejects_unsupported_file_type(registered_user, client):
    files = {"file": ("virus.exe", b"not a real file", "application/octet-stream")}
    response = client.post("/api/v1/documents/upload", headers=registered_user["headers"], files=files)
    assert response.status_code == 422


def test_metadata_rejects_short_description(registered_user, client):
    headers = registered_user["headers"]
    doc_id = _upload(client, headers).json()["data"]["id"]
    response = client.post(f"/api/v1/documents/{doc_id}/metadata", headers=headers, json={
        "title": "My Notes", "description": "too short", "category": "Mathematics",
        "level": "Advanced Level", "language": "en",
    })
    assert response.status_code == 422
    assert "500 words" in response.json()["error"]["message"]


def test_full_submit_flow_needs_revision_without_metadata(registered_user, client):
    headers = registered_user["headers"]
    doc_id = _upload(client, headers).json()["data"]["id"]
    response = client.post(f"/api/v1/documents/{doc_id}/submit", headers=headers)
    assert response.status_code == 422  # no title/description set yet


def test_full_submit_flow_succeeds_with_valid_metadata(registered_user, client):
    from tests.conftest import make_valid_description, make_valid_pdf_bytes
    headers = registered_user["headers"]
    doc_id = _upload(client, headers, content=make_valid_pdf_bytes()).json()["data"]["id"]
    meta = client.post(f"/api/v1/documents/{doc_id}/metadata", headers=headers, json={
        "title": "GCE Mathematics Notes", "description": make_valid_description("mathematics"),
        "category": "Mathematics", "level": "Advanced Level", "language": "en",
    })
    assert meta.status_code == 200

    submit = client.post(f"/api/v1/documents/{doc_id}/submit", headers=headers)
    assert submit.status_code == 200, submit.text
    assert submit.json()["data"]["status"] in ("UnderReview", "NeedsRevision")
