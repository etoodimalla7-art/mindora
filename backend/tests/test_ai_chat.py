"""AI chat over real HTTP — greeting vs. question routing, style
preference persistence, and conversation history."""


def test_chat_greeting_and_question(registered_user, client):
    headers = registered_user["headers"]
    greeting = client.post("/api/v1/ai/chat", headers=headers, json={"message": "Hello!"})
    assert greeting.status_code == 200
    assert greeting.json()["data"]["intent"] == "greeting"
    assert greeting.json()["data"]["tools_used"] == []

    question = client.post("/api/v1/ai/chat", headers=headers, json={"message": "What is a derivative?"})
    assert question.status_code == 200
    assert question.json()["data"]["intent"] == "question"


def test_conversation_persists_and_lists(registered_user, client):
    headers = registered_user["headers"]
    first = client.post("/api/v1/ai/chat", headers=headers, json={"message": "Explain derivatives"})
    conv_id = first.json()["data"]["conversation_id"]

    followup = client.post(
        "/api/v1/ai/chat", headers=headers, json={"message": "And integrals?", "conversation_id": conv_id},
    )
    assert followup.json()["data"]["conversation_id"] == conv_id

    conversations = client.get("/api/v1/ai/conversations", headers=headers)
    assert len(conversations.json()["data"]) == 1

    messages = client.get(f"/api/v1/ai/conversations/{conv_id}", headers=headers)
    assert len(messages.json()["data"]) == 4  # 2 user + 2 assistant


def test_style_preference_persists_across_messages(registered_user, client):
    headers = registered_user["headers"]
    first = client.post(
        "/api/v1/ai/chat", headers=headers, json={"message": "Explain derivatives more simply"},
    )
    assert first.json()["data"]["style_preferences"].get("depth") == "simpler"
    conv_id = first.json()["data"]["conversation_id"]

    second = client.post(
        "/api/v1/ai/chat", headers=headers,
        json={"message": "What about integrals?", "conversation_id": conv_id},
    )
    assert second.json()["data"]["style_preferences"].get("depth") == "simpler"


def test_empty_message_rejected(registered_user, client):
    response = client.post("/api/v1/ai/chat", headers=registered_user["headers"], json={"message": "   "})
    assert response.status_code == 422


def test_cross_user_conversation_access_blocked(registered_user, client):
    headers = registered_user["headers"]
    conv_id = client.post("/api/v1/ai/chat", headers=headers, json={"message": "Hi"}).json()["data"]["conversation_id"]

    other_email = "other-chat-user@test.com"
    other_reg = client.post("/api/v1/auth/register", json={"email": other_email, "password": "supersecret1"})
    other_headers = {"Authorization": f"Bearer {other_reg.json()['data']['access_token']}"}

    response = client.get(f"/api/v1/ai/conversations/{conv_id}", headers=other_headers)
    assert response.status_code == 404
