"""Audit service — write audit logs + query them."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditLog

logger = logging.getLogger(__name__)


class AuditService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def log(
        self,
        *,
        admin_id: uuid.UUID | None,
        admin_email: str | None,
        action: str,
        resource_type: str | None = None,
        resource_id: uuid.UUID | None = None,
        before: dict[str, Any] | None = None,
        after: dict[str, Any] | None = None,
        ip_address: str | None = None,
        user_agent: str | None = None,
        result: str = "success",
        error: str | None = None,
    ) -> AuditLog:
        """Write an audit log entry. Never fails the caller."""
        try:
            entry = AuditLog(
                admin_id=admin_id,
                admin_email=admin_email,
                action=action,
                resource_type=resource_type,
                resource_id=resource_id,
                before=before,
                after=after,
                ip_address=ip_address,
                user_agent=user_agent,
                result=result,
                error=error,
            )
            self.session.add(entry)
            await self.session.flush()
            return entry
        except Exception as exc:  # noqa: BLE001
            logger.exception("audit_log_failed action=%s error=%s", action, exc)
            # Don't propagate: audit must never break the main operation
            raise

    async def list_logs(
        self,
        *,
        admin_id: uuid.UUID | None = None,
        action: str | None = None,
        resource_type: str | None = None,
        since: datetime | None = None,
        until: datetime | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> list[AuditLog]:
        stmt = select(AuditLog).order_by(AuditLog.created_at.desc())
        if admin_id:
            stmt = stmt.where(AuditLog.admin_id == admin_id)
        if action:
            stmt = stmt.where(AuditLog.action == action)
        if resource_type:
            stmt = stmt.where(AuditLog.resource_type == resource_type)
        if since:
            stmt = stmt.where(AuditLog.created_at >= since)
        if until:
            stmt = stmt.where(AuditLog.created_at <= until)
        stmt = stmt.limit(limit).offset(offset)
        return list((await self.session.execute(stmt)).scalars().all())
