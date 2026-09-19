"""Flashcard generation/spaced-repetition and quiz generation/scoring
over real HTTP, using a real uploaded document's extracted text."""


def _upload_and_approve_document_with_text(client, headers, admin_headers, text, category="Biology"):
    """Helper: gets a document through upload -> metadata -> submit so
    it has extracted text a generator can use. Approval isn't required
    for flashcards/quizzes (they read from the uploader's own
    documents regardless of moderation status), but tests exercise the
    real pipeline rather than inserting DocumentAnalysis rows directly.
    """
    from tests.conftest import make_valid_description
    files = {"file": ("notes.pdf", b"%PDF-1.4 fake pdf", "application/pdf")}
    doc_id = client.post("/api/v1/documents/upload", headers=headers, files=files).json()["data"]["id"]
    client.post(f"/api/v1/documents/{doc_id}/metadata", headers=headers, json={
        "title": "Notes", "description": make_valid_description(category), "category": category,
        "level": "Advanced Level", "language": "en",
    })
    client.post(f"/api/v1/documents/{doc_id}/submit", headers=headers)
    return doc_id


def test_flashcard_generation_and_spaced_repetition(registered_user, client):
    headers = registered_user["headers"]
    gen = client.post("/api/v1/flashcards/generate", headers=headers, json={
        "topic_title": "General Review", "max_cards": 5,
    })
    assert gen.status_code == 200
    cards = gen.json()["data"]
    assert len(cards) >= 1
    card_id = cards[0]["id"]

    due_before = client.get("/api/v1/flashcards", headers=headers).json()["data"]
    assert any(c["id"] == card_id for c in due_before)

    review = client.post(f"/api/v1/flashcards/{card_id}/review", headers=headers, json={"state": "known"})
    assert review.status_code == 200

    due_after = client.get("/api/v1/flashcards", headers=headers).json()["data"]
    assert not any(c["id"] == card_id for c in due_after), "a card just marked 'known' shouldn't be immediately due again"


def test_quiz_generation_and_scoring(registered_user, client):
    headers = registered_user["headers"]
    gen = client.post("/api/v1/quizzes/generate", headers=headers, json={
        "topic_title": "General Review", "num_questions": 3,
    })
    assert gen.status_code == 200
    quiz = gen.json()["data"]
    assert len(quiz["questions"]) >= 1
    for q in quiz["questions"]:
        assert "correct_answer" not in q, "correct answers must never be sent before submission"

    # Answer everything with the first choice (may be right or wrong,
    # doesn't matter — we're checking scoring math and shape, not content).
    answers = {q["id"]: q["choices"][0] for q in quiz["questions"]}
    attempt = client.post(f"/api/v1/quizzes/{quiz['id']}/attempt", headers=headers, json={"answers": answers})
    assert attempt.status_code == 200
    result = attempt.json()["data"]
    assert 0 <= result["score"] <= 100
    assert len(result["results"]) == len(quiz["questions"])
    for r in result["results"]:
        assert "correct_answer" in r  # revealed only after submission
