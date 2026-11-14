"""Support Center service (Phase 6.2)."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.models.support import (
    TICKET_PRIORITY_NORMAL,
    TICKET_PRIORITIES,
    TICKET_STATUS_CLOSED,
    TICKET_STATUS_IN_PROGRESS,
    TICKET_STATUS_OPEN,
    TICKET_STATUS_RESOLVED,
    TICKET_STATUSES,
    SupportMessage,
    SupportTicket,
)
from app.models.user import User
from app.schemas.support import (
    SupportMessageOut,
    SupportStatsOut,
    TicketAssign,
    TicketCreate,
    TicketDetailOut,
    TicketRespond,
    TicketRow,
)

logger = logging.getLogger(__name__)


class SupportService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Helpers ----------

    async def _row_to_dto(
        self, row: SupportTicket, user_email: str | None, admin_email: str | None
    ) -> TicketRow:
        return TicketRow(
            id=row.id,
            subject=row.subject,
            description=row.description,
            status=row.status,
            priority=row.priority,
            assigned_to=row.assigned_to,
            user_id=row.user_id,
            user_email=user_email,
            assigned_to_email=admin_email,
            resolved_at=row.resolved_at,
            created_at=row.created_at,
            updated_at=row.updated_at,
        )

    async def _fetch_email(self, user_id: uuid.UUID | None) -> str | None:
        if not user_id:
            return None
        r = (
            await self.session.execute(
                select(User.email).where(User.id == user_id)
            )
        ).scalar_one_or_none()
        return r

    # ---------- List / Get ----------

    async def list_tickets(
        self,
        status: str | None = None,
        priority: str | None = None,
        assigned_to: uuid.UUID | None = None,
        q: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[TicketRow], int]:
        # Base query
        stmt = select(SupportTicket)
        if status:
            if status not in TICKET_STATUSES:
                raise ValidationError(f"Statut invalide : {status}")
            stmt = stmt.where(SupportTicket.status == status)
        if priority:
            if priority not in TICKET_PRIORITIES:
                raise ValidationError(f"Priorité invalide : {priority}")
            stmt = stmt.where(SupportTicket.priority == priority)
        if assigned_to:
            stmt = stmt.where(SupportTicket.assigned_to == assigned_to)
        if q:
            like = f"%{q}%"
            stmt = stmt.where(
                or_(
                    SupportTicket.subject.ilike(like),
                    SupportTicket.description.ilike(like),
                )
            )

        # Count
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = (await self.session.execute(count_stmt)).scalar_one()

        # Order & paginate
        stmt = stmt.order_by(SupportTicket.created_at.desc()).limit(limit).offset(offset)
        rows = (await self.session.execute(stmt)).scalars().all()

        # Enrich with emails
        items: list[TicketRow] = []
        for row in rows:
            user_email = await self._fetch_email(row.user_id)
            admin_email = await self._fetch_email(row.assigned_to)
            items.append(
                await self._row_to_dto(row, user_email, admin_email)
            )
        return items, total

    async def get_ticket(self, ticket_id: uuid.UUID) -> TicketDetailOut:
        row = (
            await self.session.execute(
                select(SupportTicket).where(SupportTicket.id == ticket_id)
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError("Ticket introuvable.")

        user_email = await self._fetch_email(row.user_id)
        admin_email = await self._fetch_email(row.assigned_to)

        # Messages
        msg_stmt = (
            select(SupportMessage)
            .where(SupportMessage.ticket_id == ticket_id)
            .order_by(SupportMessage.created_at.asc())
        )
        msgs = (await self.session.execute(msg_stmt)).scalars().all()
        messages: list[SupportMessageOut] = []
        for m in msgs:
            author_email = await self._fetch_email(m.author_id)
            messages.append(
                SupportMessageOut(
                    id=m.id,
                    ticket_id=m.ticket_id,
                    author_id=m.author_id,
                    author_email=author_email,
                    body=m.body,
                    is_admin=m.is_admin,
                    created_at=m.created_at,
                )
            )

        base = await self._row_to_dto(row, user_email, admin_email)
        return TicketDetailOut(**base.model_dump(), messages=messages)

    # ---------- Create ----------

    async def create_ticket(
        self,
        payload: TicketCreate,
        creator_id: uuid.UUID,
    ) -> TicketRow:
        # Si user_id fourni, on vérifie qu'il existe
        user_id = payload.user_id or creator_id
        exists = (
            await self.session.execute(select(User.id).where(User.id == user_id))
        ).scalar_one_or_none()
        if not exists:
            raise NotFoundError("Utilisateur introuvable.")

        row = SupportTicket(
            user_id=user_id,
            subject=payload.subject,
            description=payload.description,
            status=TICKET_STATUS_OPEN,
            priority=payload.priority,
        )
        self.session.add(row)
        await self.session.commit()
        await self.session.refresh(row)

        user_email = await self._fetch_email(row.user_id)
        return await self._row_to_dto(row, user_email, None)

    # ---------- Respond ----------

    async def respond(
        self,
        ticket_id: uuid.UUID,
        payload: TicketRespond,
        author_id: uuid.UUID,
        is_admin: bool = True,
    ) -> SupportMessageOut:
        ticket = (
            await self.session.execute(
                select(SupportTicket).where(SupportTicket.id == ticket_id)
            )
        ).scalar_one_or_none()
        if not ticket:
            raise NotFoundError("Ticket introuvable.")
        if ticket.status == TICKET_STATUS_CLOSED:
            raise ValidationError("Impossible de répondre à un ticket fermé.")

        msg = SupportMessage(
            ticket_id=ticket_id,
            author_id=author_id,
            body=payload.body,
            is_admin=is_admin,
        )
        self.session.add(msg)

        # Auto transition: open → in_progress
        if ticket.status == TICKET_STATUS_OPEN:
            ticket.status = TICKET_STATUS_IN_PROGRESS
            ticket.updated_at = datetime.now(timezone.utc)

        await self.session.commit()
        await self.session.refresh(msg)

        author_email = await self._fetch_email(author_id)
        return SupportMessageOut(
            id=msg.id,
            ticket_id=msg.ticket_id,
            author_id=msg.author_id,
            author_email=author_email,
            body=msg.body,
            is_admin=msg.is_admin,
            created_at=msg.created_at,
        )

    # ---------- Assign ----------

    async def assign(
        self,
        ticket_id: uuid.UUID,
        payload: TicketAssign,
    ) -> TicketRow:
        ticket = (
            await self.session.execute(
                select(SupportTicket).where(SupportTicket.id == ticket_id)
            )
        ).scalar_one_or_none()
        if not ticket:
            raise NotFoundError("Ticket introuvable.")

        # Vérifier que l'admin existe
        admin_exists = (
            await self.session.execute(
                select(User.id).where(User.id == payload.assigned_to)
            )
        ).scalar_one_or_none()
        if not admin_exists:
            raise NotFoundError("Utilisateur assigné introuvable.")

        ticket.assigned_to = payload.assigned_to
        ticket.updated_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(ticket)

        user_email = await self._fetch_email(ticket.user_id)
        admin_email = await self._fetch_email(ticket.assigned_to)
        return await self._row_to_dto(ticket, user_email, admin_email)

    # ---------- Status ----------

    async def update_status(
        self,
        ticket_id: uuid.UUID,
        new_status: str,
    ) -> TicketRow:
        if new_status not in TICKET_STATUSES:
            raise ValidationError(f"Statut invalide : {new_status}")

        ticket = (
            await self.session.execute(
                select(SupportTicket).where(SupportTicket.id == ticket_id)
            )
        ).scalar_one_or_none()
        if not ticket:
            raise NotFoundError("Ticket introuvable.")

        ticket.status = new_status
        ticket.updated_at = datetime.now(timezone.utc)
        if new_status in (TICKET_STATUS_RESOLVED, TICKET_STATUS_CLOSED):
            ticket.resolved_at = datetime.now(timezone.utc)
        else:
            ticket.resolved_at = None

        await self.session.commit()
        await self.session.refresh(ticket)

        user_email = await self._fetch_email(ticket.user_id)
        admin_email = await self._fetch_email(ticket.assigned_to)
        return await self._row_to_dto(ticket, user_email, admin_email)

    # ---------- Stats ----------

    async def stats(self) -> SupportStatsOut:
        # Count par statut
        stmt = select(SupportTicket.status, func.count(SupportTicket.id)).group_by(
            SupportTicket.status
        )
        rows = (await self.session.execute(stmt)).all()
        by_status = {s: c for s, c in rows}

        # Count par priorité
        stmt2 = select(
            SupportTicket.priority, func.count(SupportTicket.id)
        ).group_by(SupportTicket.priority)
        rows2 = (await self.session.execute(stmt2)).all()
        by_priority = {p: c for p, c in rows2}

        total = sum(by_status.values())

        return SupportStatsOut(
            total=total,
            open=by_status.get(TICKET_STATUS_OPEN, 0),
            in_progress=by_status.get(TICKET_STATUS_IN_PROGRESS, 0),
            resolved=by_status.get(TICKET_STATUS_RESOLVED, 0),
            closed=by_status.get(TICKET_STATUS_CLOSED, 0),
            by_priority=by_priority,
        )
