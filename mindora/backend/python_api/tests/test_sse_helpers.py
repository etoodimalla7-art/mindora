"""Tests for SSE helpers."""
from app.services.sse import sse_event, sse_ping


def test_sse_event_format():
    out = sse_event("token", {"text": "hello"})
    assert "event: token\n" in out
    assert 'data: {"text":"hello"}\n' in out
    assert out.endswith("\n\n")


def test_sse_event_unicode():
    out = sse_event("token", {"text": "café ☕"})
    assert "café ☕" in out


def test_sse_ping():
    out = sse_ping()
    assert out.startswith(":")
    assert out.endswith("\n\n")
