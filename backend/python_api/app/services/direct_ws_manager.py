"""WebSocket connection manager for Direct 1-to-1 messages (Phase 13.7)."""
from __future__ import annotations

import json
import logging
import uuid
from collections import defaultdict

from fastapi import WebSocket

logger = logging.getLogger(__name__)


class DirectConnectionManager:
    def __init__(self) -> None:
        # conversation_id -> {user_id -> set[WebSocket]}
        self._connections: dict[uuid.UUID, dict[uuid.UUID, set[WebSocket]]] = (
            defaultdict(lambda: defaultdict(set))
        )
        self._sockets: dict[WebSocket, tuple[uuid.UUID, uuid.UUID]] = {}

    async def connect(
        self,
        conversation_id: uuid.UUID,
        user_id: uuid.UUID,
        websocket: WebSocket,
    ) -> None:
        await websocket.accept()
        self._connections[conversation_id][user_id].add(websocket)
        self._sockets[websocket] = (conversation_id, user_id)

    def disconnect(
        self, conversation_id: uuid.UUID, user_id: uuid.UUID, websocket: WebSocket
    ) -> None:
        self._connections[conversation_id][user_id].discard(websocket)
        if not self._connections[conversation_id][user_id]:
            self._connections[conversation_id].pop(user_id, None)
        if not self._connections[conversation_id]:
            self._connections.pop(conversation_id, None)
        self._sockets.pop(websocket, None)

    async def send_to_user(
        self,
        conversation_id: uuid.UUID,
        user_id: uuid.UUID,
        payload: dict,
    ) -> None:
        sockets = list(self._connections.get(conversation_id, {}).get(user_id, set()))
        if not sockets:
            return
        text = json.dumps(payload, default=str)
        dead: list[WebSocket] = []
        for ws in sockets:
            try:
                await ws.send_text(text)
            except Exception as exc:  # noqa: BLE001
                logger.warning("direct_ws_send_failed error=%s", exc)
                dead.append(ws)
        for ws in dead:
            self.disconnect(conversation_id, user_id, ws)

    async def broadcast_to_conversation(
        self, conversation_id: uuid.UUID, payload: dict
    ) -> None:
        for user_id in list(self._connections.get(conversation_id, {}).keys()):
            await self.send_to_user(conversation_id, user_id, payload)


manager = DirectConnectionManager()
