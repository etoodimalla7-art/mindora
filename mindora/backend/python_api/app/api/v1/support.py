"""Student Support & Public Contact endpoints."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.support import (
    PublicContactRequest,
    PublicContactResponse,
    SupportMessageOut,
    TicketCreate,
    TicketDetailOut,
    TicketRespond,
    TicketRow,
)
from app.services.event_bus import event_bus
from app.services.support_service import SupportService

router = APIRouter()


@router.get("/tickets", response_model=list[TicketRow])
@router.get("/tickets/mine", response_model=list[TicketRow])
async def list_my_tickets(
    session: SessionDep,
    user_id: CurrentUserId,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[TicketRow]:
    return await SupportService(session).list_user_tickets(
        user_id, limit=limit, offset=offset
    )


@router.post("/tickets", response_model=TicketRow, status_code=201)
async def create_my_ticket(
    payload: TicketCreate,
    session: SessionDep,
    user_id: CurrentUserId,
) -> TicketRow:
    sanitized = TicketCreate(
        subject=payload.subject,
        description=payload.description,
        priority=payload.priority,
        category=payload.category,
        user_id=user_id,
    )
    row = await SupportService(session).create_ticket(sanitized, user_id)
    await event_bus.publish(
        "support.ticket_created",
        {"ticket_id": str(row.id), "subject": row.subject, "priority": row.priority},
    )
    return row


@router.get("/tickets/{ticket_id}", response_model=TicketDetailOut)
async def get_my_ticket(
    ticket_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> TicketDetailOut:
    return await SupportService(session).get_user_ticket(user_id, ticket_id)


@router.post(
    "/tickets/{ticket_id}/messages",
    response_model=SupportMessageOut,
    status_code=201,
)
async def reply_my_ticket(
    ticket_id: uuid.UUID,
    payload: TicketRespond,
    session: SessionDep,
    user_id: CurrentUserId,
) -> SupportMessageOut:
    svc = SupportService(session)
    await svc.get_user_ticket(user_id, ticket_id)
    return await svc.respond(
        ticket_id, payload, author_id=user_id, is_admin=False
    )


@router.post("/contact", response_model=PublicContactResponse, status_code=201)
async def submit_contact_form(
    payload: PublicContactRequest,
    session: SessionDep,
) -> PublicContactResponse:
    """Public contact form endpoint (no auth required)."""
    row = await SupportService(session).create_contact_ticket(
        name=payload.name,
        email=payload.email,
        subject=payload.subject,
        message=payload.message,
        category=payload.category,
    )
    await event_bus.publish(
        "support.contact",
        {"ticket_id": str(row.id), "subject": row.subject},
    )
    return PublicContactResponse(
        ticket_id=row.id,
        status=row.status,
        message="Message received. Our support team will get back to you shortly.",
    )
