"""ID generation helpers."""
from __future__ import annotations

import uuid


def new_uuid() -> uuid.UUID:
    """Return a new UUIDv4."""
    return uuid.uuid4()


def new_request_id() -> str:
    """Short request identifier for logging / tracing."""
    return uuid.uuid4().hex[:16]
