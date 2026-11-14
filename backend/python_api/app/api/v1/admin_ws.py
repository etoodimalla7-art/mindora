"""WebSocket endpoint for real-time admin events."""
from __future__ import annotations

import asyncio
import json
import logging
import uuid

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect

from app.core.security import decode_token
from app.db.session import AsyncSessionLocal
from app.services.event_bus import Subscriber, event_bus
from app.services.role_service import RoleService

logger = logging.getLogger(__name__)

router = APIRouter()


async def _authenticate(token: str) -> uuid.UUID:
    payload = decode_token(token, expected_type="access")
    sub = payload.get("sub")
    if not sub:
        raise ValueError("Invalid token.")
    return uuid.UUID(sub)


async def _get_permissions(user_id: uuid.UUID) -> set[str]:
    async with AsyncSessionLocal() as session:
        return await RoleService(session).get_effective_permissions(user_id)


@router.websocket("/events")
async def admin_events_ws(
    websocket: WebSocket,
    token: str = Query(..., description="JWT access token"),
) -> None:
    try:
        user_id = await _authenticate(token)
    except Exception as exc:  # noqa: BLE001
        logger.warning("admin_ws_auth_failed error=%s", exc)
        await websocket.close(code=4401)
        return

    perms = await _get_permissions(user_id)
    if not perms:
        logger.warning("admin_ws_no_perms user=%s", user_id)
        await websocket.close(code=4403)
        return

    await websocket.accept()
    logger.info("admin_ws_connected user=%s", user_id)

    # Send initial connection
    await websocket.send_json({
        "type": "connected",
        "payload": {
            "user_id": str(user_id),
            "permissions_count": len(perms),
        },
    })

    # Subscriber handler: directly awaits WS send (no queue)
    async def handler(message: dict) -> None:
        await websocket.send_json(message)

    sub: Subscriber = event_bus.subscribe(handler, perms)

    # Keep connection alive + handle pings
    try:
        while True:
            try:
                raw = await asyncio.wait_for(websocket.receive_text(), timeout=30.0)
                try:
                    data = json.loads(raw)
                except json.JSONDecodeError:
                    continue
                if data.get("type") == "ping":
                    await websocket.send_json({"type": "pong"})
            except asyncio.TimeoutError:
                # Send heartbeat ping to keep proxies happy
                await websocket.send_json({"type": "ping"})
    except WebSocketDisconnect:
        pass
    except Exception as exc:  # noqa: BLE001
        logger.debug("admin_ws_error: %s", exc)
    finally:
        event_bus.unsubscribe(sub.id)
        logger.info("admin_ws_disconnected user=%s", user_id)
