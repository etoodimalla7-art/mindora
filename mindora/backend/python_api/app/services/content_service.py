"""Content CMS + broadcast service (Phase 5)."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.models.content import BroadcastNotification, ContentString
from app.models.curriculum import Announcement, Chapter, Subject
from app.models.notification import Notification, NotificationPreference
from app.models.user import EducationProfile, User
from app.schemas.admin_content import (
    AnnouncementCreate,
    AnnouncementOut,
    AnnouncementUpdate,
    BroadcastCreate,
    BroadcastOut,
    ChapterCreate,
    ChapterOut,
    ChapterUpdate,
    ContentStringCreate,
    ContentStringOut,
    ContentStringUpdate,
    SubjectCreate,
    SubjectOut,
    SubjectUpdate,
)
from app.services.audit_service import AuditService

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

    # ---------- Subjects (CRUD + soft delete + audit) ----------

    async def list_subjects(self, *, include_deleted: bool = False) -> list[SubjectOut]:
        stmt = select(Subject).order_by(Subject.display_order.asc(), Subject.name_fr.asc())
        if not include_deleted:
            stmt = stmt.where(Subject.deleted_at.is_(None))
        rows = (await self.session.execute(stmt)).scalars().all()
        return [SubjectOut.model_validate(r) for r in rows]

    async def create_subject(
        self,
        payload: SubjectCreate,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> SubjectOut:
        dup = (
            await self.session.execute(
                select(Subject).where(Subject.slug == payload.slug)
            )
        ).scalar_one_or_none()
        if dup:
            raise ValidationError(f"Subject slug '{payload.slug}' already exists.")

        row = Subject(
            slug=payload.slug,
            name_fr=payload.name_fr,
            name_en=payload.name_en,
            exam_systems=payload.exam_systems,
            display_order=payload.display_order,
            is_active=payload.is_active,
            created_by=admin_id,
            updated_by=admin_id,
        )
        self.session.add(row)
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="subject.create",
            resource_type="subject",
            resource_id=row.id,
            after={"slug": row.slug, "name_fr": row.name_fr, "name_en": row.name_en},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return SubjectOut.model_validate(row)

    async def update_subject(
        self,
        subject_id: uuid.UUID,
        payload: SubjectUpdate,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> SubjectOut:
        row = (
            await self.session.execute(
                select(Subject).where(Subject.id == subject_id, Subject.deleted_at.is_(None))
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError("Subject not found.")

        before = {"name_fr": row.name_fr, "name_en": row.name_en, "is_active": row.is_active}
        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(row, field, value)
        row.updated_by = admin_id
        row.updated_at = datetime.now(timezone.utc)
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="subject.update",
            resource_type="subject",
            resource_id=row.id,
            before=before,
            after={"name_fr": row.name_fr, "name_en": row.name_en, "is_active": row.is_active},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return SubjectOut.model_validate(row)

    async def delete_subject(
        self,
        subject_id: uuid.UUID,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> SubjectOut:
        row = (
            await self.session.execute(
                select(Subject).where(Subject.id == subject_id, Subject.deleted_at.is_(None))
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError("Subject not found.")

        now = datetime.now(timezone.utc)
        row.deleted_at = now
        row.is_active = False
        row.updated_by = admin_id
        row.updated_at = now
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="subject.delete",
            resource_type="subject",
            resource_id=row.id,
            before={"slug": row.slug, "deleted_at": None},
            after={"slug": row.slug, "deleted_at": now.isoformat()},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return SubjectOut.model_validate(row)

    # ---------- Chapters (CRUD + soft delete + audit) ----------

    async def list_chapters(
        self,
        *,
        subject_id: uuid.UUID | None = None,
        include_deleted: bool = False,
    ) -> list[ChapterOut]:
        stmt = select(Chapter).order_by(Chapter.order_index.asc(), Chapter.title_fr.asc())
        if not include_deleted:
            stmt = stmt.where(Chapter.deleted_at.is_(None))
        if subject_id is not None:
            stmt = stmt.where(Chapter.subject_id == subject_id)
        rows = (await self.session.execute(stmt)).scalars().all()
        return [ChapterOut.model_validate(r) for r in rows]

    async def create_chapter(
        self,
        payload: ChapterCreate,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> ChapterOut:
        subj = (
            await self.session.execute(
                select(Subject).where(
                    Subject.id == payload.subject_id, Subject.deleted_at.is_(None)
                )
            )
        ).scalar_one_or_none()
        if not subj:
            raise NotFoundError("Subject not found.")

        row = Chapter(
            subject_id=payload.subject_id,
            title_fr=payload.title_fr,
            title_en=payload.title_en,
            summary_fr=payload.summary_fr,
            summary_en=payload.summary_en,
            level=payload.level,
            order_index=payload.order_index,
            is_published=payload.is_published,
            created_by=admin_id,
            updated_by=admin_id,
        )
        self.session.add(row)
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="chapter.create",
            resource_type="chapter",
            resource_id=row.id,
            after={"subject_id": str(row.subject_id), "title_fr": row.title_fr},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return ChapterOut.model_validate(row)

    async def update_chapter(
        self,
        chapter_id: uuid.UUID,
        payload: ChapterUpdate,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> ChapterOut:
        row = (
            await self.session.execute(
                select(Chapter).where(Chapter.id == chapter_id, Chapter.deleted_at.is_(None))
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError("Chapter not found.")

        before = {"title_fr": row.title_fr, "title_en": row.title_en, "is_published": row.is_published}
        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(row, field, value)
        row.updated_by = admin_id
        row.updated_at = datetime.now(timezone.utc)
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="chapter.update",
            resource_type="chapter",
            resource_id=row.id,
            before=before,
            after={"title_fr": row.title_fr, "title_en": row.title_en, "is_published": row.is_published},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return ChapterOut.model_validate(row)

    async def delete_chapter(
        self,
        chapter_id: uuid.UUID,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> ChapterOut:
        row = (
            await self.session.execute(
                select(Chapter).where(Chapter.id == chapter_id, Chapter.deleted_at.is_(None))
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError("Chapter not found.")

        now = datetime.now(timezone.utc)
        row.deleted_at = now
        row.is_published = False
        row.updated_by = admin_id
        row.updated_at = now
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="chapter.delete",
            resource_type="chapter",
            resource_id=row.id,
            before={"title_fr": row.title_fr, "deleted_at": None},
            after={"title_fr": row.title_fr, "deleted_at": now.isoformat()},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return ChapterOut.model_validate(row)

    # ---------- Announcements (CRUD + soft delete + audit) ----------

    async def list_announcements(
        self, *, include_deleted: bool = False
    ) -> list[AnnouncementOut]:
        stmt = select(Announcement).order_by(Announcement.created_at.desc())
        if not include_deleted:
            stmt = stmt.where(Announcement.deleted_at.is_(None))
        rows = (await self.session.execute(stmt)).scalars().all()
        return [AnnouncementOut.model_validate(r) for r in rows]

    async def create_announcement(
        self,
        payload: AnnouncementCreate,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> AnnouncementOut:
        row = Announcement(
            title_fr=payload.title_fr,
            title_en=payload.title_en,
            body_fr=payload.body_fr,
            body_en=payload.body_en,
            audience=payload.audience,
            priority=payload.priority,
            is_published=payload.is_published,
            starts_at=payload.starts_at,
            ends_at=payload.ends_at,
            created_by=admin_id,
            updated_by=admin_id,
        )
        self.session.add(row)
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="announcement.create",
            resource_type="announcement",
            resource_id=row.id,
            after={"title_fr": row.title_fr, "audience": row.audience, "priority": row.priority},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return AnnouncementOut.model_validate(row)

    async def update_announcement(
        self,
        announcement_id: uuid.UUID,
        payload: AnnouncementUpdate,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> AnnouncementOut:
        row = (
            await self.session.execute(
                select(Announcement).where(
                    Announcement.id == announcement_id,
                    Announcement.deleted_at.is_(None),
                )
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError("Announcement not found.")

        before = {"title_fr": row.title_fr, "is_published": row.is_published}
        for field, value in payload.model_dump(exclude_unset=True).items():
            setattr(row, field, value)
        row.updated_by = admin_id
        row.updated_at = datetime.now(timezone.utc)
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="announcement.update",
            resource_type="announcement",
            resource_id=row.id,
            before=before,
            after={"title_fr": row.title_fr, "is_published": row.is_published},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return AnnouncementOut.model_validate(row)

    async def delete_announcement(
        self,
        announcement_id: uuid.UUID,
        *,
        admin_id: uuid.UUID,
        admin_email: str | None = None,
    ) -> AnnouncementOut:
        row = (
            await self.session.execute(
                select(Announcement).where(
                    Announcement.id == announcement_id,
                    Announcement.deleted_at.is_(None),
                )
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError("Announcement not found.")

        now = datetime.now(timezone.utc)
        row.deleted_at = now
        row.is_published = False
        row.updated_by = admin_id
        row.updated_at = now
        await self.session.flush()
        await AuditService(self.session).log(
            admin_id=admin_id,
            admin_email=admin_email,
            action="announcement.delete",
            resource_type="announcement",
            resource_id=row.id,
            before={"title_fr": row.title_fr, "deleted_at": None},
            after={"title_fr": row.title_fr, "deleted_at": now.isoformat()},
        )
        await self.session.commit()
        await self.session.refresh(row)
        return AnnouncementOut.model_validate(row)
