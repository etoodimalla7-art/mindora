"""Auth session repository (refresh token rotation)."""
from __future__ import annotations

import hashlib
import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.session import Session


def _hash(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


class SessionRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def create(
        self,
        *,
        user_id: uuid.UUID,
        refresh_token: str,
        user_agent: str | None,
        ip_address: str | None,
    ) -> Session:
        entity = Session(
            user_id=user_id,
            refresh_token_hash=_hash(refresh_token),
            user_agent=(user_agent or "")[:255] or None,
            ip_address=(ip_address or "")[:64] or None,
            expires_at=datetime.now(UTC)
            + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS),
        )
        self.session.add(entity)
        await self.session.flush()
        return entity

    async def get_active_by_token(self, refresh_token: str) -> Session | None:
        """Return the most recent active session matching the token hash."""
        stmt = (
            select(Session)
            .where(
                Session.refresh_token_hash == _hash(refresh_token),
                Session.revoked_at.is_(None),
                Session.expires_at > datetime.now(UTC),
            )
            .order_by(Session.created_at.desc())
            .limit(1)
        )
        return (await self.session.execute(stmt)).scalar_one_or_none()

    async def revoke(self, session: Session) -> None:
        session.revoked_at = datetime.now(UTC)
        await self.session.flush()

    async def revoke_all_by_token(self, refresh_token: str) -> int:
        """Revoke ALL active sessions matching this token hash.

        Returns the number of sessions revoked.
        """
        token_hash = _hash(refresh_token)
        stmt = select(Session).where(
            Session.refresh_token_hash == token_hash,
            Session.revoked_at.is_(None),
        )
        rows = list((await self.session.execute(stmt)).scalars().all())
        now = datetime.now(UTC)
        for row in rows:
            row.revoked_at = now
        await self.session.flush()
        return len(rows)

    async def revoke_all_for_user(self, user_id: uuid.UUID) -> None:
        stmt = select(Session).where(
            Session.user_id == user_id, Session.revoked_at.is_(None)
        )
        rows = (await self.session.execute(stmt)).scalars().all()
        now = datetime.now(UTC)
        for row in rows:
            row.revoked_at = now
        await self.session.flush()
