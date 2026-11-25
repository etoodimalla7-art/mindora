"""SSE helpers — robust emitter with keep-alive + proper escaping.

Format used (per W3C EventSource spec):
    event: <name>\\n
    data: <json>\\n
    \\n

Blank line terminates each event.
"""
from __future__ import annotations

import json
import logging
from typing import Any

logger = logging.getLogger(__name__)

PING_INTERVAL_SECONDS = 15


def sse_event(event: str, data: dict[str, Any]) -> str:
    """Format a single SSE event. Handles multi-line JSON safely."""
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    # Each data line must be prefixed. We send a single-line JSON so it's simple.
    return f"event: {event}\ndata: {payload}\n\n"


def sse_ping() -> str:
    """Keep-alive ping (client can safely ignore)."""
    return ": ping\n\n"
