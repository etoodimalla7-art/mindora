"""Content CMS + broadcast service (Phase 5)."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.models.content import BroadcastNotification, ContentString
from app.models.notification import Notification, NotificationPreference
from app.models.user import EducationProfile, User
from app.schemas.admin_content import (
    BroadcastCreate,
    BroadcastOut,
    ContentStringCreate,
    ContentStringOut,
    ContentStringUpdate,
)

logger = logging.getLogger(__name__)


class ContentService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Content strings ----------

    async def list_strings(self, group: str | None = None) -> list[ContentStringOut]:
        stmt = select(ContentString).order_by(ContentString.group, ContentString.key)
        if group:
            stmt = stmt.where(ContentString.group == group)
        rows = (await self.session.execute(stmt)).scalars().all()
        return [ContentStringOut.model_validate(r) for r in rows]

    async def get_string(self, key: str) -> ContentStringOut:
        row = (
            await self.session.execute(
                select(ContentString).where(ContentString.key == key)
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError(f"Content string '{key}' not found.")
        return ContentStringOut.model_validate(row)

    async def update_string(
        self,
        key: str,
        payload: ContentStringUpdate,
        updated_by: uuid.UUID | None = None,
    ) -> ContentStringOut:
        row = (
            await self.session.execute(
                select(ContentString).where(ContentString.key == key)
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError(f"Content string '{key}' not found.")
        if payload.value_fr is not None:
            row.value_fr = payload.value_fr
        if payload.value_en is not None:
            row.value_en = payload.value_en
        if payload.description is not None:
            row.description = payload.description
        row.updated_by = updated_by
        row.updated_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(row)
        return ContentStringOut.model_validate(row)

    async def create_string(
        self,
        payload: ContentStringCreate,
        updated_by: uuid.UUID | None = None,
    ) -> ContentStringOut:
        existing = (
            await self.session.execute(
                select(ContentString).where(ContentString.key == payload.key)
            )
        ).scalar_one_or_none()
        if existing:
            raise ValidationError(f"Content string '{payload.key}' already exists.")
        row = ContentString(
            key=payload.key,
            description=payload.description,
            value_fr=payload.value_fr,
            value_en=payload.value_en,
            group=payload.group,
            updated_by=updated_by,
        )
        self.session.add(row)
        await self.session.commit()
        await self.session.refresh(row)
        return ContentStringOut.model_validate(row)

    # ---------- Broadcasts ----------

    async def list_broadcasts(self, limit: int = 50) -> list[BroadcastOut]:
        stmt = (
            select(BroadcastNotification)
            .order_by(BroadcastNotification.created_at.desc())
            .limit(limit)
        )
        rows = (await self.session.execute(stmt)).scalars().all()
        return [BroadcastOut.model_validate(r) for r in rows]

    async def create_broadcast(
        self,
        payload: BroadcastCreate,
        created_by: uuid.UUID | None = None,
        send_now: bool = True,
    ) -> BroadcastOut:
        b = BroadcastNotification(
            title=payload.title,
            body=payload.body,
            target_criteria=payload.target_criteria or {},
            scheduled_at=payload.scheduled_at,
            created_by=created_by,
        )
        self.session.add(b)
        await self.session.flush()

        if send_now and not payload.scheduled_at:
            await self._send_broadcast(b)

        await self.session.commit()
        await self.session.refresh(b)
        return BroadcastOut.model_validate(b)

    async def _send_broadcast(self, b: BroadcastNotification) -> None:
        """Find target users and create Notification rows for each."""
        stmt = select(User).where(User.is_active.is_(True))

        crit = b.target_criteria or {}
        if role := crit.get("role"):
            if role == "admin":
                stmt = stmt.where(User.is_admin.is_(True))
            elif role == "user":
                stmt = stmt.where(User.is_admin.is_(False))

        if crit.get("level") or crit.get("system"):
            stmt = stmt.join(
                EducationProfile, EducationProfile.user_id == User.id
            )
            if level := crit.get("level"):
                stmt = stmt.where(EducationProfile.level == level)
            if system := crit.get("system"):
                stmt = stmt.where(EducationProfile.education_system == system)

        users = (await self.session.execute(stmt)).scalars().all()

        count = 0
        for u in users:
            n = Notification(
                user_id=u.id,
                type="broadcast",
                title=b.title,
                body=b.body,
                template_key="broadcast",
                metadata_json={
                    "broadcast_id": str(b.id),
                    "criteria": crit,
                },
            )
            self.session.add(n)
            count += 1

        b.sent_at = datetime.now(timezone.utc)
        b.sent_count = count
        logger.info(
            "broadcast_sent id=%s count=%d criteria=%s",
            b.id, count, crit,
        )
