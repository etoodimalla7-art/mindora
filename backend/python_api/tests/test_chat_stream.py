"""Test the SSE streaming endpoint."""
from __future__ import annotations

import uuid

import pytest


def _email() -> str:
    return f"stream_{uuid.uuid4().hex[:8]}@example.com"


@pytest.mark.asyncio
async def test_chat_stream_yields_tokens(client):
    # 1. Register a fresh user
    email = _email()
    r = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "StreamPass123!",
            "full_name": "Stream User",
            "preferred_language": "en",
            "country_code": "CM",
        },
    )
    assert r.status_code == 201, r.text
    token = r.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Open the streaming endpoint
    async with client.stream(
        "POST",
        "/api/v1/ai/chat/stream",
        json={"message": "Say OK."},
        headers=headers,
    ) as response:
        assert response.status_code == 200
        assert "text/event-stream" in response.headers.get("content-type", "")

        buffer = ""
        saw_meta = False
        saw_token = False
        saw_done = False

        async for chunk in response.aiter_text():
            buffer += chunk
            while "\n\n" in buffer:
                block, buffer = buffer.split("\n\n", 1)
                lines = block.strip().split("\n")
                event = None
                data = ""
                for line in lines:
                    if line.startswith("event: "):
                        event = line[7:]
                    elif line.startswith("data: "):
                        data = line[6:]
                if event == "meta":
                    saw_meta = True
                elif event == "token":
                    saw_token = True
                elif event == "done":
                    saw_done = True
            if saw_done:
                break

        assert saw_meta, "did not see meta event"
        assert saw_token, "did not see any token event"
        assert saw_done, "did not see done event"
