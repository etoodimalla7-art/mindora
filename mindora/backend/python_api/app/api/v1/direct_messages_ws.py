"""WebSocket endpoint for Direct 1-to-1 chat (Phase 13.7)."""
from __future__ import annotations

import logging
import uuid

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from sqlalchemy import select

from app.core.errors import AppError
from app.core.security import decode_token
from app.db.session import AsyncSessionLocal
from app.models.direct_message import DirectConversation
from app.schemas.direct_message import DirectMessageCreate
from app.services.direct_message_service import DirectMessageService
from app.services.direct_ws_manager import manager

logger = logging.getLogger(__name__)

router = APIRouter()


async def _authenticate(token: str) -> uuid.UUID:
    payload = decode_token(token, expected_type="access")
    sub = payload.get("sub")
    if not sub:
        raise AppError("Invalid token.", code="unauthorized", status_code=401)
    return uuid.UUID(sub)


async def _is_participant(
    user_id: uuid.UUID, conversation_id: uuid.UUID
) -> bool:
    async with AsyncSessionLocal() as session:
        conv = (
            await session.execute(
                select(DirectConversation).where(
                    DirectConversation.id == conversation_id
                )
            )
        ).scalar_one_or_none()
        if conv is None:
            return False
        return conv.user_a_id == user_id or conv.user_b_id == user_id


@router.websocket("/{conversation_id}/ws")
async def direct_ws(
    websocket: WebSocket,
    conversation_id: uuid.UUID,
    token: str = Query(..., description="JWT access token"),
) -> None:
    try:
        user_id = await _authenticate(token)
    except Exception as exc:  # noqa: BLE001
        logger.warning("direct_ws_auth_failed error=%s", exc)
        await websocket.close(code=4401)
        return

    if not await _is_participant(user_id, conversation_id):
        await websocket.close(code=4403)
        return

    await manager.connect(conversation_id, user_id, websocket)

    try:
        while True:
            raw = await websocket.receive_json()
            content = (raw or {}).get("content", "").strip()
            if not content:
                continue
            if len(content) > 4000:
                await websocket.send_json(
                    {"type": "error", "message": "Message too long (max 4000)."}
                )
                continue

            async with AsyncSessionLocal() as session:
                try:
                    svc = DirectMessageService(session)
                    msg = await svc.post_message(
                        user_id,
                        conversation_id,
                        DirectMessageCreate(content=content),
                    )
                except Exception as exc:  # noqa: BLE001
                    logger.exception("direct_ws_persist_failed")
                    await websocket.send_json(
                        {"type": "error", "message": str(exc)}
                    )
                    continue

            await manager.broadcast_to_conversation(
                conversation_id,
                {"type": "message", "data": msg.model_dump(mode="json")},
            )
    except WebSocketDisconnect:
        logger.info(
            "direct_ws_client_disconnect conv=%s user=%s",
            conversation_id,
            user_id,
        )
    except Exception as exc:  # noqa: BLE001
        logger.exception("direct_ws_unexpected_error: %s", exc)
    finally:
        manager.disconnect(conversation_id, user_id, websocket)
