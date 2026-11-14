"""Admin Support Center endpoints (Phase 6.2)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.schemas.support import (
    SupportMessageOut,
    SupportStatsOut,
    TicketAssign,
    TicketCreate,
    TicketDetailOut,
    TicketListOut,
    TicketRespond,
    TicketRow,
    TicketStatusUpdate,
)
from app.services.role_service import RoleService
from app.services.support_service import SupportService

router = APIRouter()


async def _require_read(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.SUPPORT_READ)


async def _require_write(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.SUPPORT_WRITE)


async def _require_assign(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.SUPPORT_ASSIGN)


# ---------- List / Get ----------


@router.get("/support/tickets", response_model=TicketListOut)
async def list_tickets(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    status: str | None = Query(default=None),
    priority: str | None = Query(default=None),
    assigned_to: uuid.UUID | None = Query(default=None),
    q: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> TicketListOut:
    await _require_read(session, current_user_id)
    items, total = await SupportService(session).list_tickets(
        status=status,
        priority=priority,
        assigned_to=assigned_to,
        q=q,
        limit=limit,
        offset=offset,
    )
    return TicketListOut(items=items, total=total, limit=limit, offset=offset)


@router.get("/support/tickets/{ticket_id}", response_model=TicketDetailOut)
async def get_ticket(
    ticket_id: uuid.UUID,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> TicketDetailOut:
    await _require_read(session, current_user_id)
    return await SupportService(session).get_ticket(ticket_id)


# ---------- Create ----------


@router.post("/support/tickets", response_model=TicketRow, status_code=201)
async def create_ticket(
    payload: TicketCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> TicketRow:
    await _require_write(session, current_user_id)
    return await SupportService(session).create_ticket(payload, current_user_id)


# ---------- Respond ----------


@router.post(
    "/support/tickets/{ticket_id}/messages",
    response_model=SupportMessageOut,
    status_code=201,
)
async def respond(
    ticket_id: uuid.UUID,
    payload: TicketRespond,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> SupportMessageOut:
    await _require_write(session, current_user_id)
    return await SupportService(session).respond(
        ticket_id, payload, author_id=current_user_id, is_admin=True
    )


# ---------- Assign ----------


@router.patch("/support/tickets/{ticket_id}/assign", response_model=TicketRow)
async def assign(
    ticket_id: uuid.UUID,
    payload: TicketAssign,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> TicketRow:
    await _require_assign(session, current_user_id)
    return await SupportService(session).assign(ticket_id, payload)


# ---------- Status ----------


@router.patch("/support/tickets/{ticket_id}/status", response_model=TicketRow)
async def update_status(
    ticket_id: uuid.UUID,
    payload: TicketStatusUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> TicketRow:
    await _require_write(session, current_user_id)
    return await SupportService(session).update_status(ticket_id, payload.status)


# ---------- Stats ----------


@router.get("/support/stats", response_model=SupportStatsOut)
async def stats(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> SupportStatsOut:
    await _require_read(session, current_user_id)
    return await SupportService(session).stats()
