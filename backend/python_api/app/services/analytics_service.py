"""Analytics service — aggregated stats for admin dashboard."""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, AsyncIterator

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditLog
from app.models.conversation import Conversation, Message
from app.models.document import (
    DOC_STATUS_APPROVED,
    DOC_STATUS_REJECTED,
    DOC_STATUS_UNDER_REVIEW,
    Document,
)
from app.models.mock_exam import MockExam
from app.models.paper import PAPER_STATUS_PUBLISHED, Paper
from app.models.session import Session as UserSession
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

    # ---------- Recent activity ----------

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

    # ============================================================
    # PHASE 6.1 — Advanced analytics
    # ============================================================

    async def retention_cohorts(self, weeks: int = 8) -> list[dict[str, Any]]:
        """Weekly signup cohort retention.

        For each ISO week W (last `weeks` weeks), compute:
          - cohort_size = users created in W
          - retention[i] = % of those users active (session created) at week W+i
        Activity = presence of at least one Session row (any login) in that week.

        Returns list ordered oldest → newest, each with retention[0] = 100.0.
        """
        if weeks < 1:
            weeks = 1
        if weeks > 26:
            weeks = 26

        now = datetime.now(timezone.utc)
        # Anchor to start of current week (Monday 00:00)
        anchor = (now - timedelta(days=now.weekday())).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
        start = anchor - timedelta(weeks=weeks - 1)

        # Fetch (user_id, signup_week, session_week) tuples for users in window
        sql = text(
            """
            WITH cohort AS (
                SELECT
                    u.id                              AS user_id,
                    date_trunc('week', u.created_at)  AS cohort_week
                FROM users u
                WHERE u.created_at >= :start
                  AND u.created_at <  :end
                  AND u.deleted_at IS NULL
            ),
            activity AS (
                SELECT
                    s.user_id,
                    date_trunc('week', s.created_at) AS active_week
                FROM sessions s
                WHERE s.created_at >= :start
                  AND s.created_at <  :end_plus_max
                GROUP BY s.user_id, date_trunc('week', s.created_at)
            )
            SELECT
                c.cohort_week,
                c.user_id,
                a.active_week
            FROM cohort c
            LEFT JOIN activity a ON a.user_id = c.user_id
        """
        )
        result = await self.session.execute(
            sql,
            {
                "start": start,
                "end": anchor + timedelta(weeks=1),
                "end_plus_max": anchor + timedelta(weeks=weeks + 1),
            },
        )
        rows = result.all()

        # Aggregate: cohort_week -> {user_id -> set(active_weeks)}
        cohort_users: dict[datetime, dict] = {}
        for r in rows:
            cw = r.cohort_week
            if cw not in cohort_users:
                cohort_users[cw] = {"size": 0, "users": {}}
            uid = r.user_id
            if uid not in cohort_users[cw]["users"]:
                cohort_users[cw]["size"] += 1
                cohort_users[cw]["users"][uid] = set()
            if r.active_week is not None:
                cohort_users[cw]["users"][uid].add(r.active_week)

        # Build retention curve for each cohort
        output: list[dict[str, Any]] = []
        for cw in sorted(cohort_users.keys()):
            entry = cohort_users[cw]
            size = entry["size"]
            max_offset = (anchor - cw).days // 7  # 0..weeks-1
            curve: list[float] = []
            for offset in range(max_offset + 1):
                target_week = cw + timedelta(weeks=offset)
                active = sum(
                    1
                    for weeks_set in entry["users"].values()
                    if target_week in weeks_set
                )
                pct = round((active / size * 100.0), 1) if size else 0.0
                curve.append(pct)
            iso_year, iso_week, _ = cw.isocalendar()
            output.append(
                {
                    "cohort_week": f"{iso_year}-W{iso_week:02d}",
                    "cohort_size": size,
                    "retention": curve,
                }
            )
        return output

    async def engagement_funnel(self, days: int = 30) -> dict[str, Any]:
        """Engagement funnel over the last N days.

        Each stage counts users who reached THIS stage AND all previous stages
        (cumulative subset). Guarantees monotonic non-increasing counts.

        Stages:
          1. signup        — User created in window
          2. verified      — + User.is_verified = true
          3. onboarding    — + has EducationProfile
          4. first_chat    — + has at least one Conversation
          5. first_mock    — + has at least one MockExam
          6. subscribed    — + has at least one Subscription
        """
        if days < 1:
            days = 1
        if days > 365:
            days = 365

        now = datetime.now(timezone.utc)
        start = now - timedelta(days=days)

        # Step 1 — signups in window
        signup_ids = set(
            (
                await self.session.execute(
                    select(User.id).where(
                        User.created_at >= start,
                        User.deleted_at.is_(None),
                    )
                )
            ).scalars().all()
        )
        total_signups = len(signup_ids)

        if total_signups == 0:
            return {
                "days": days,
                "total_signups": 0,
                "stages": [
                    {"key": k, "label": l, "count": 0,
                     "conversion_from_prev": 100.0 if i == 0 else 0.0,
                     "conversion_from_start": 0.0}
                    for i, (k, l) in enumerate([
                        ("signup", "Inscription"),
                        ("verified", "Email vérifié"),
                        ("onboarding", "Onboarding complété"),
                        ("first_chat", "Premier chat IA"),
                        ("first_mock", "Premier mock exam"),
                        ("subscribed", "Abonné"),
                    ])
                ],
            }

        # Step 2 — verified subset
        verified_ids = set(
            (
                await self.session.execute(
                    select(User.id).where(
                        User.id.in_(signup_ids),
                        User.is_verified.is_(True),
                    )
                )
            ).scalars().all()
        )

        # Step 3 — onboarding subset (EducationProfile among verified)
        try:
            from app.models.user import EducationProfile
            onboarding_ids = set(
                (
                    await self.session.execute(
                        select(func.distinct(EducationProfile.user_id)).where(
                            EducationProfile.user_id.in_(verified_ids),
                        )
                    )
                ).scalars().all()
            )
        except Exception:
            onboarding_ids = set()

        # Step 4 — first_chat subset (Conversation among onboarding)
        if onboarding_ids:
            chat_ids = set(
                (
                    await self.session.execute(
                        select(func.distinct(Conversation.user_id)).where(
                            Conversation.user_id.in_(onboarding_ids),
                        )
                    )
                ).scalars().all()
            )
        else:
            chat_ids = set()

        # Step 5 — first_mock subset (MockExam among chat)
        if chat_ids:
            mock_ids = set(
                (
                    await self.session.execute(
                        select(func.distinct(MockExam.user_id)).where(
                            MockExam.user_id.in_(chat_ids),
                        )
                    )
                ).scalars().all()
            )
        else:
            mock_ids = set()

        # Step 6 — subscribed subset (Subscription among mock)
        if mock_ids:
            try:
                from app.models.subscription import Subscription
                paid_ids = set(
                    (
                        await self.session.execute(
                            select(func.distinct(Subscription.user_id)).where(
                                Subscription.user_id.in_(mock_ids),
                            )
                        )
                    ).scalars().all()
                )
            except Exception:
                paid_ids = set()
        else:
            paid_ids = set()

        stages_raw = [
            ("signup", "Inscription", total_signups),
            ("verified", "Email vérifié", len(verified_ids)),
            ("onboarding", "Onboarding complété", len(onboarding_ids)),
            ("first_chat", "Premier chat IA", len(chat_ids)),
            ("first_mock", "Premier mock exam", len(mock_ids)),
            ("subscribed", "Abonné", len(paid_ids)),
        ]

        stages: list[dict[str, Any]] = []
        prev_count = None
        start_count = total_signups or 1
        for idx, (key, label, count) in enumerate(stages_raw):
            if idx == 0:
                from_prev = 100.0
            else:
                from_prev = (
                    round(count / prev_count * 100.0, 1) if prev_count else 0.0
                )
            from_start = round(count / start_count * 100.0, 1)
            stages.append(
                {
                    "key": key,
                    "label": label,
                    "count": count,
                    "conversion_from_prev": from_prev,
                    "conversion_from_start": from_start,
                }
            )
            prev_count = count

        return {
            "days": days,
            "total_signups": total_signups,
            "stages": stages,
        }

    async def export_users_csv(
        self,
        filters: dict[str, Any] | None = None,
    ) -> AsyncIterator[bytes]:
        """Stream users as CSV. Filters: verified (bool|None), role (str|None)."""
        filters = filters or {}
        verified = filters.get("verified")
        role = filters.get("role")

        stmt = (
            select(
                User.email,
                User.created_at,
                User.is_verified,
                User.is_admin,
                User.last_login_at,
            )
            .where(User.deleted_at.is_(None))
            .order_by(User.created_at.desc())
        )
        if verified is True:
            stmt = stmt.where(User.is_verified.is_(True))
        elif verified is False:
            stmt = stmt.where(User.is_verified.is_(False))

        # Header
        yield b"email,created_at,is_verified,role,last_login_at\n"

        result = await self.session.stream(stmt)
        async for row in result:
            email = (row.email or "").replace(",", " ")
            created = row.created_at.isoformat() if row.created_at else ""
            verified_str = "true" if row.is_verified else "false"
            role_str = "admin" if row.is_admin else "user"
            last_login = row.last_login_at.isoformat() if row.last_login_at else ""
            line = f"{email},{created},{verified_str},{role_str},{last_login}\n"
            yield line.encode("utf-8")
