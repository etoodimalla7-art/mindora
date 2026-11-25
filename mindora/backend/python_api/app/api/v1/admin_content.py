"""Admin Content CMS + broadcast endpoints (Phase 5)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
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
from app.services.content_service import ContentService
from app.services.role_service import RoleService

router = APIRouter()


async def _require_content_manage(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.CONTENT_MANAGE)


async def _require_notif_manage(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.NOTIFICATIONS_MANAGE)


# ---------- Content strings ----------

@router.get("/content", response_model=list[ContentStringOut])
async def list_content(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    group: str | None = Query(default=None),
) -> list[ContentStringOut]:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).list_strings(group)


@router.get("/content/{key}", response_model=ContentStringOut)
async def get_content(
    key: str,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> ContentStringOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).get_string(key)


@router.post("/content", response_model=ContentStringOut, status_code=201)
async def create_content(
    payload: ContentStringCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> ContentStringOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).create_string(
        payload, updated_by=current_user_id
    )


@router.patch("/content/{key}", response_model=ContentStringOut)
async def update_content(
    key: str,
    payload: ContentStringUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> ContentStringOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).update_string(
        key, payload, updated_by=current_user_id
    )


# ---------- Broadcasts ----------

@router.get("/broadcasts", response_model=list[BroadcastOut])
async def list_broadcasts(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[BroadcastOut]:
    await _require_notif_manage(session, current_user_id)
    return await ContentService(session).list_broadcasts()


@router.post("/broadcasts", response_model=BroadcastOut, status_code=201)
async def create_broadcast(
    payload: BroadcastCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> BroadcastOut:
    await _require_notif_manage(session, current_user_id)
    return await ContentService(session).create_broadcast(
        payload, created_by=current_user_id
    )


# ---------- Subjects ----------


@router.get("/subjects", response_model=list[SubjectOut])
async def list_subjects(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[SubjectOut]:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).list_subjects()


@router.post("/subjects", response_model=SubjectOut, status_code=201)
async def create_subject(
    payload: SubjectCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> SubjectOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).create_subject(
        payload,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


@router.put("/subjects/{subject_id}", response_model=SubjectOut)
async def update_subject(
    subject_id: uuid.UUID,
    payload: SubjectUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> SubjectOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).update_subject(
        subject_id,
        payload,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


@router.delete("/subjects/{subject_id}", response_model=SubjectOut)
async def delete_subject(
    subject_id: uuid.UUID,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> SubjectOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).delete_subject(
        subject_id,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


# ---------- Chapters ----------


@router.get("/chapters", response_model=list[ChapterOut])
async def list_chapters(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
    subject_id: uuid.UUID | None = Query(default=None),
) -> list[ChapterOut]:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).list_chapters(subject_id=subject_id)


@router.post("/chapters", response_model=ChapterOut, status_code=201)
async def create_chapter(
    payload: ChapterCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> ChapterOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).create_chapter(
        payload,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


@router.put("/chapters/{chapter_id}", response_model=ChapterOut)
async def update_chapter(
    chapter_id: uuid.UUID,
    payload: ChapterUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> ChapterOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).update_chapter(
        chapter_id,
        payload,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


@router.delete("/chapters/{chapter_id}", response_model=ChapterOut)
async def delete_chapter(
    chapter_id: uuid.UUID,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> ChapterOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).delete_chapter(
        chapter_id,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


# ---------- Announcements ----------


@router.get("/announcements", response_model=list[AnnouncementOut])
async def list_announcements(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[AnnouncementOut]:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).list_announcements()


@router.post("/announcements", response_model=AnnouncementOut, status_code=201)
async def create_announcement(
    payload: AnnouncementCreate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> AnnouncementOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).create_announcement(
        payload,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


@router.put("/announcements/{announcement_id}", response_model=AnnouncementOut)
async def update_announcement(
    announcement_id: uuid.UUID,
    payload: AnnouncementUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> AnnouncementOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).update_announcement(
        announcement_id,
        payload,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


@router.delete("/announcements/{announcement_id}", response_model=AnnouncementOut)
async def delete_announcement(
    announcement_id: uuid.UUID,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> AnnouncementOut:
    await _require_content_manage(session, current_user_id)
    return await ContentService(session).delete_announcement(
        announcement_id,
        admin_id=current_user_id,
        admin_email=getattr(admin, "email", None),
    )
