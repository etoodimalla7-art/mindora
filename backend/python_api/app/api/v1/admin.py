"""Admin routes — documents moderation, users, papers, stats."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, File, Form, Query, Response, UploadFile

from app.api.deps import AdminUser, SessionDep
from app.schemas.admin import (
    AdminDocumentRow,
    AdminStatsOut,
    AdminUserRow,
    ApproveResponse,
    PaperDetail,
    PaperRow,
    PromoteResponse,
    RejectRequest,
    RejectResponse,
    ToggleActiveResponse,
)
from app.services.admin_service import AdminService

router = APIRouter()


# ---------- Documents (existing) ----------

@router.get("/documents", response_model=list[AdminDocumentRow])
async def list_documents(
    session: SessionDep,
    _admin: AdminUser,
    status_filter: str | None = Query(default=None, alias="status"),
    limit: int = Query(default=100, ge=1, le=500),
) -> list[AdminDocumentRow]:
    return await AdminService(session).list_documents(status_filter, limit)


@router.post("/documents/{doc_id}/approve", response_model=ApproveResponse)
async def approve_document(
    doc_id: uuid.UUID, session: SessionDep, _admin: AdminUser
) -> ApproveResponse:
    return await AdminService(session).approve(doc_id)


@router.post("/documents/{doc_id}/reject", response_model=RejectResponse)
async def reject_document(
    doc_id: uuid.UUID,
    payload: RejectRequest,
    session: SessionDep,
    _admin: AdminUser,
) -> RejectResponse:
    return await AdminService(session).reject(doc_id, payload.reason)


# ---------- Stats ----------

@router.get("/stats", response_model=AdminStatsOut)
async def get_stats(session: SessionDep, _admin: AdminUser) -> AdminStatsOut:
    return await AdminService(session).get_stats()


# ---------- Users ----------

@router.get("/users", response_model=list[AdminUserRow])
async def list_users(
    session: SessionDep,
    _admin: AdminUser,
    search: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[AdminUserRow]:
    return await AdminService(session).list_users(search, limit, offset)


@router.post("/users/{user_id}/toggle-active", response_model=ToggleActiveResponse)
async def toggle_user_active(
    user_id: uuid.UUID, session: SessionDep, _admin: AdminUser
) -> ToggleActiveResponse:
    return await AdminService(session).toggle_user_active(user_id)


@router.post("/users/{user_id}/promote", response_model=PromoteResponse)
async def promote_user(
    user_id: uuid.UUID, session: SessionDep, _admin: AdminUser
) -> PromoteResponse:
    return await AdminService(session).promote_user(user_id)


# ---------- Papers (upload + list + delete) ----------

@router.post("/papers", response_model=PaperDetail)
async def create_paper(
    session: SessionDep,
    admin: AdminUser,
    title: str = Form(...),
    subject: str = Form(...),
    exam_system: str = Form(...),
    exam_level: str = Form(...),
    language: str = Form("fr"),
    exam_year: int | None = Form(None),
    description: str | None = Form(None),
    file: UploadFile = File(...),
) -> PaperDetail:
    file_data = await file.read()
    return await AdminService(session).create_paper(
        uploader_id=admin.id,
        title=title,
        subject=subject,
        exam_system=exam_system,
        exam_level=exam_level,
        exam_year=exam_year,
        language=language,
        description=description,
        file_name=file.filename or "unknown",
        file_data=file_data,
        mime_type=file.content_type or "application/octet-stream",
    )


@router.get("/papers", response_model=list[PaperRow])
async def list_papers(
    session: SessionDep,
    _admin: AdminUser,
    subject: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[PaperRow]:
    return await AdminService(session).list_papers(subject, limit, offset)


@router.get("/papers/{paper_id}", response_model=PaperDetail)
async def get_paper(
    paper_id: uuid.UUID, session: SessionDep, _admin: AdminUser
) -> PaperDetail:
    return await AdminService(session).get_paper(paper_id)


@router.delete("/papers/{paper_id}", status_code=204)
async def delete_paper(
    paper_id: uuid.UUID, session: SessionDep, _admin: AdminUser
) -> Response:
    await AdminService(session).delete_paper(paper_id)
    return Response(status_code=204)
