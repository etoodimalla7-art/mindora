"""WebSocket endpoint for real-time Study Group chat (Phase 13)."""
from __future__ import annotations

import logging
import uuid

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from sqlalchemy import select

from app.core.errors import AppError
from app.core.security import decode_token
from app.db.session import AsyncSessionLocal
from app.models.study_group import StudyGroupMember
from app.schemas.study_group import GroupMessageCreate
from app.services.study_group_service import StudyGroupService
from app.services.ws_manager import manager

logger = logging.getLogger(__name__)

router = APIRouter()


async def _authenticate(token: str) -> uuid.UUID:
    """Decode the JWT and return the user_id. Raises on invalid token."""
    payload = decode_token(token, expected_type="access")
    sub = payload.get("sub")
    if not sub:
        raise AppError("Invalid token.", code="unauthorized", status_code=401)
    return uuid.UUID(sub)


async def _assert_member(user_id: uuid.UUID, group_id: uuid.UUID) -> bool:
    async with AsyncSessionLocal() as session:
        exists = (
            await session.execute(
                select(StudyGroupMember.id).where(
                    StudyGroupMember.group_id == group_id,
                    StudyGroupMember.user_id == user_id,
                )
            )
        ).scalar_one_or_none()
        return exists is not None


@router.websocket("/{group_id}/ws")
async def study_group_ws(
    websocket: WebSocket,
    group_id: uuid.UUID,
    token: str = Query(..., description="JWT access token"),
) -> None:
    """Real-time chat for a study group.

    Protocol:
      - Client connects: ws://.../study-groups/{id}/ws?token=JWT
      - Client sends:  {"content": "..."}   (JSON)
      - Server broadcasts: {"type": "message", "data": {...GroupMessageOut}}
      - Server also sends: {"type": "presence", "count": N} on join/leave
    """
    # 1. Auth (before accept — close if invalid)
    try:
        user_id = await _authenticate(token)
    except Exception as exc:  # noqa: BLE001
        logger.warning("ws_auth_failed error=%s", exc)
        await websocket.close(code=4401)  # 4401 = custom "Unauthorized"
        return

    # 2. Membership check
    if not await _assert_member(user_id, group_id):
        logger.warning("ws_membership_denied group=%s user=%s", group_id, user_id)
        await websocket.close(code=4403)  # 4403 = custom "Forbidden"
        return

    # 3. Accept & register
    await manager.connect(group_id, user_id, websocket)
    await manager.broadcast(
        group_id, {"type": "presence", "count": manager.count(group_id)}
    )

    try:
        while True:
            # Client → Server: expect JSON {"content": "..."}
            raw = await websocket.receive_json()
            content = (raw or {}).get("content", "").strip()
            if not content:
                continue
            if len(content) > 2000:
                await websocket.send_json(
                    {"type": "error", "message": "Message too long (max 2000)."}
                )
                continue

            # Persist via REST service (single source of truth)
            async with AsyncSessionLocal() as session:
                try:
                    svc = StudyGroupService(session)
                    msg = await svc.post_message(
                        user_id, group_id, GroupMessageCreate(content=content)
                    )
                except Exception as exc:  # noqa: BLE001
                    logger.exception("ws_persist_failed")
                    await websocket.send_json(
                        {"type": "error", "message": str(exc)}
                    )
                    continue

            # Broadcast to all members
            await manager.broadcast(
                group_id,
                {"type": "message", "data": msg.model_dump(mode="json")},
            )

    except WebSocketDisconnect:
        logger.info("ws_client_disconnect group=%s user=%s", group_id, user_id)
    except Exception as exc:  # noqa: BLE001
        logger.exception("ws_unexpected_error: %s", exc)
    finally:
        manager.disconnect(group_id, websocket)
        await manager.broadcast(
            group_id, {"type": "presence", "count": manager.count(group_id)}
        )
