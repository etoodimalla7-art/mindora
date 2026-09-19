from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.notifications.models import Notification, NotificationPreference


class NotificationsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_or_create_preferences(self, user_id: str) -> NotificationPreference:
        uid = to_uuid(user_id)
        result = await self.db.execute(select(NotificationPreference).where(NotificationPreference.user_id == uid))
        prefs = result.scalar_one_or_none()
        if prefs:
            return prefs
        prefs = NotificationPreference(user_id=uid)
        self.db.add(prefs)
        await self.db.commit()
        await self.db.refresh(prefs)
        return prefs

    async def update_preferences(self, user_id: str, data: dict) -> NotificationPreference:
        prefs = await self.get_or_create_preferences(user_id)
        for key, value in data.items():
            setattr(prefs, key, value)
        await self.db.commit()
        await self.db.refresh(prefs)
        return prefs

    async def create(
        self, user_id: str, notif_type: str, title: str, body: str, payload: dict, scheduled_for: datetime,
    ) -> Notification:
        notification = Notification(
            user_id=to_uuid(user_id), type=notif_type, title=title, body=body,
            payload=payload, scheduled_for=scheduled_for,
        )
        self.db.add(notification)
        await self.db.commit()
        await self.db.refresh(notification)
        return notification

    async def exists_with_payload_value(self, user_id: str, notif_type: str, key: str, value: str) -> bool:
        """Dedupe check across small, per-student notification volumes —
        fetched and filtered in Python rather than a JSON-containment
        SQL query, matching this codebase's established small-scale
        pattern (see documents' duplicate-check note in Phase 5)."""
        result = await self.db.execute(
            select(Notification)
            .where(Notification.user_id == to_uuid(user_id))
            .where(Notification.type == notif_type)
        )
        return any(n.payload.get(key) == value for n in result.scalars().all())

    async def list_for_user(self, user_id: str) -> list[Notification]:
        result = await self.db.execute(
            select(Notification)
            .where(Notification.user_id == to_uuid(user_id))
            .order_by(Notification.scheduled_for.desc())
        )
        return list(result.scalars().all())

    async def mark_read(self, notification_id: str, user_id: str, read_at: datetime) -> Notification | None:
        result = await self.db.execute(
            select(Notification)
            .where(Notification.id == to_uuid(notification_id))
            .where(Notification.user_id == to_uuid(user_id))
        )
        notification = result.scalar_one_or_none()
        if notification:
            notification.read_at = read_at
            await self.db.commit()
            await self.db.refresh(notification)
        return notification
