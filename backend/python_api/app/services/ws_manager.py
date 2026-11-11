"""WebSocket connection manager for Study Groups (Phase 13).

Tracks active connections per group and broadcasts messages to all
members of that group.
"""
from __future__ import annotations

import json
import logging
import uuid
from collections import defaultdict

from fastapi import WebSocket

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Singleton-ish manager — one instance per process.

    In a multi-worker deployment (uvicorn --workers N), each worker has its
    own in-memory manager. Cross-worker broadcasting would require Redis
    pub/sub. For Phase 13 MVP, we accept single-worker mode (default uvicorn
    without --workers).
    """

    def __init__(self) -> None:
        # group_id -> set of active WebSockets
        self._connections: dict[uuid.UUID, set[WebSocket]] = defaultdict(set)
        # websocket -> user_id (for cleanup + display)
        self._users: dict[WebSocket, uuid.UUID] = {}

    async def connect(
        self, group_id: uuid.UUID, user_id: uuid.UUID, websocket: WebSocket
    ) -> None:
        await websocket.accept()
        self._connections[group_id].add(websocket)
        self._users[websocket] = user_id
        logger.info(
            "ws_connect group=%s user=%s total=%d",
            group_id,
            user_id,
            len(self._connections[group_id]),
        )

    def disconnect(self, group_id: uuid.UUID, websocket: WebSocket) -> None:
        self._connections[group_id].discard(websocket)
        self._users.pop(websocket, None)
        if not self._connections[group_id]:
            self._connections.pop(group_id, None)
        logger.info("ws_disconnect group=%s", group_id)

    async def broadcast(
        self, group_id: uuid.UUID, payload: dict
    ) -> None:
        """Send a JSON payload to every socket in the group."""
        sockets = list(self._connections.get(group_id, set()))
        if not sockets:
            return
        text = json.dumps(payload, default=str)
        dead: list[WebSocket] = []
        for ws in sockets:
            try:
                await ws.send_text(text)
            except Exception as exc:  # noqa: BLE001
                logger.warning("ws_broadcast_failed error=%s", exc)
                dead.append(ws)
        for ws in dead:
            self.disconnect(group_id, ws)

    def count(self, group_id: uuid.UUID) -> int:
        return len(self._connections.get(group_id, set()))


# Single global instance, imported everywhere.
manager = ConnectionManager()
