"""Session Management service (Phase 7.3)."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.session import Session
from app.models.user import User
from app.schemas.sessions import SessionListOut, SessionRow

logger = logging.getLogger(__name__)


class SessionService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Helpers ----------

    async def _to_row(self, s: Session) -> SessionRow:
        user_email: str | None = None
        is_admin = False
        u = (
            await self.session.execute(
                select(User.email, User.is_admin).where(User.id == s.user_id)
            )
        ).first()
        if u:
            user_email = u[0]
            is_admin = bool(u[1])

        now = datetime.now(timezone.utc)
        # expires_at is tz-aware in DB
        is_expired = s.expires_at <= now if s.expires_at else False

        return SessionRow(
            id=s.id,
            user_id=s.user_id,
            user_email=user_email,
            is_admin=is_admin,
            is_expired=is_expired,
            expires_at=s.expires_at,
            created_at=s.created_at,
            updated_at=s.updated_at,
        )

    # ---------- List ----------

    async def list_sessions(
        self,
        user_id: uuid.UUID | None = None,
        email: str | None = None,
        admin_only: bool = False,
        include_expired: bool = False,
        limit: int = 50,
        offset: int = 0,
    ) -> SessionListOut:
        stmt = select(Session)
        if user_id:
            stmt = stmt.where(Session.user_id == user_id)
        if email:
            # find user by email substring
            uid_stmt = select(User.id).where(User.email.ilike(f"%{email}%"))
            uids = (await self.session.execute(uid_stmt)).scalars().all()
            if not uids:
                return SessionListOut(items=[], total=0, limit=limit, offset=offset)
            stmt = stmt.where(Session.user_id.in_(uids))
        if admin_only:
            admin_uids = (
                await self.session.execute(
                    select(User.id).where(User.is_admin.is_(True))
                )
            ).scalars().all()
            if not admin_uids:
                return SessionListOut(items=[], total=0, limit=limit, offset=offset)
            stmt = stmt.where(Session.user_id.in_(admin_uids))
        if not include_expired:
            stmt = stmt.where(Session.expires_at > datetime.now(timezone.utc))

        total = (
            await self.session.execute(
                select(func.count()).select_from(stmt.subquery())
            )
        ).scalar_one()

        stmt = (
            stmt.order_by(Session.updated_at.desc()).limit(limit).offset(offset)
        )
        rows = (await self.session.execute(stmt)).scalars().all()

        items = [await self._to_row(s) for s in rows]
        return SessionListOut(items=items, total=total, limit=limit, offset=offset)

    # ---------- Revoke ----------

    async def revoke_session(self, session_id: uuid.UUID) -> int:
        result = await self.session.execute(
            delete(Session).where(Session.id == session_id)
        )
        await self.session.commit()
        return int(result.rowcount or 0)

    async def revoke_user_sessions(self, user_id: uuid.UUID) -> int:
        result = await self.session.execute(
            delete(Session).where(Session.user_id == user_id)
        )
        await self.session.commit()
        return int(result.rowcount or 0)

    # ---------- Cleanup ----------

    async def cleanup_expired(self) -> int:
        result = await self.session.execute(
            delete(Session).where(
                Session.expires_at <= datetime.now(timezone.utc)
            )
        )
        await self.session.commit()
        return int(result.rowcount or 0)
