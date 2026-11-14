"""Analytics service — aggregated stats for admin dashboard."""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditLog
from app.models.document import (
    DOC_STATUS_APPROVED,
    DOC_STATUS_REJECTED,
    DOC_STATUS_UNDER_REVIEW,
    Document,
)
from app.models.paper import PAPER_STATUS_PUBLISHED, Paper
from app.models.user import User

logger = logging.getLogger(__name__)


class AnalyticsService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Overview KPIs ----------

    async def overview(self) -> dict[str, Any]:
        now = datetime.now(timezone.utc)
        week_ago = now - timedelta(days=7)
        day_ago = now - timedelta(days=1)

        users_total = (
            await self.session.execute(select(func.count(User.id)))
        ).scalar_one()
        users_new_7d = (
            await self.session.execute(
                select(func.count(User.id)).where(User.created_at >= week_ago)
            )
        ).scalar_one()
        users_active_24h = (
            await self.session.execute(
                select(func.count(func.distinct(User.id))).where(
                    User.last_login_at >= day_ago.date()
                )
            )
        ).scalar_one() if hasattr(User, "last_login_at") else 0

        docs_total = (
            await self.session.execute(select(func.count(Document.id)))
        ).scalar_one()
        docs_pending = (
            await self.session.execute(
                select(func.count(Document.id)).where(
                    Document.status == DOC_STATUS_UNDER_REVIEW
                )
            )
        ).scalar_one()
        docs_approved = (
            await self.session.execute(
                select(func.count(Document.id)).where(
                    Document.status == DOC_STATUS_APPROVED
                )
            )
        ).scalar_one()
        docs_rejected = (
            await self.session.execute(
                select(func.count(Document.id)).where(
                    Document.status == DOC_STATUS_REJECTED
                )
            )
        ).scalar_one()

        papers_total = (
            await self.session.execute(select(func.count(Paper.id)))
        ).scalar_one()
        papers_published = (
            await self.session.execute(
                select(func.count(Paper.id)).where(
                    Paper.status == PAPER_STATUS_PUBLISHED
                )
            )
        ).scalar_one()

        audit_actions_24h = (
            await self.session.execute(
                select(func.count(AuditLog.id)).where(
                    AuditLog.created_at >= day_ago
                )
            )
        ).scalar_one()

        return {
            "users": {
                "total": users_total,
                "new_7d": users_new_7d,
                "active_24h": users_active_24h,
            },
            "documents": {
                "total": docs_total,
                "pending": docs_pending,
                "approved": docs_approved,
                "rejected": docs_rejected,
            },
            "papers": {
                "total": papers_total,
                "published": papers_published,
            },
            "activity": {
                "audit_actions_24h": audit_actions_24h,
            },
        }

    # ---------- Timeseries ----------

    async def users_timeseries(self, days: int = 7) -> list[dict[str, Any]]:
        """Daily count of new users over the last N days."""
        now = datetime.now(timezone.utc)
        start = (now - timedelta(days=days)).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        stmt = (
            select(
                func.date_trunc("day", User.created_at).label("day"),
                func.count(User.id).label("count"),
            )
            .where(User.created_at >= start)
            .group_by("day")
            .order_by("day")
        )
        rows = (await self.session.execute(stmt)).all()
        return [
            {"date": r.day.isoformat(), "count": r.count}
            for r in rows
        ]

    async def documents_timeseries(
        self, days: int = 7
    ) -> list[dict[str, Any]]:
        now = datetime.now(timezone.utc)
        start = (now - timedelta(days=days)).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        stmt = (
            select(
                func.date_trunc("day", Document.created_at).label("day"),
                func.count(Document.id).label("submitted"),
            )
            .where(Document.created_at >= start)
            .group_by("day")
            .order_by("day")
        )
        rows = (await self.session.execute(stmt)).all()
        return [{"date": r.day.isoformat(), "submitted": r.submitted} for r in rows]

    # ---------- Breakdowns ----------

    async def subjects_breakdown(self) -> list[dict[str, Any]]:
        stmt = (
            select(
                Document.category.label("subject"),
                func.count(Document.id).label("count"),
            )
            .where(Document.category.isnot(None))
            .group_by(Document.category)
            .order_by(func.count(Document.id).desc())
            .limit(15)
        )
        rows = (await self.session.execute(stmt)).all()
        return [{"subject": r.subject, "count": r.count} for r in rows]

    async def exam_systems_breakdown(self) -> list[dict[str, Any]]:
        stmt = (
            select(
                Paper.exam_system.label("system"),
                func.count(Paper.id).label("count"),
            )
            .group_by(Paper.exam_system)
            .order_by(func.count(Paper.id).desc())
        )
        rows = (await self.session.execute(stmt)).all()
        return [{"system": r.system, "count": r.count} for r in rows]

    # ---------- Recent activity (from audit logs) ----------

    async def recent_activity(self, limit: int = 20) -> list[dict[str, Any]]:
        stmt = (
            select(AuditLog)
            .order_by(AuditLog.created_at.desc())
            .limit(limit)
        )
        rows = (await self.session.execute(stmt)).scalars().all()
        return [
            {
                "id": str(log.id),
                "action": log.action,
                "resource_type": log.resource_type,
                "resource_id": str(log.resource_id) if log.resource_id else None,
                "admin_email": log.admin_email,
                "result": log.result,
                "created_at": log.created_at.isoformat(),
            }
            for log in rows
        ]
