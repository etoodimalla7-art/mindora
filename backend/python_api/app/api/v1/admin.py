"""Admin routes."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query

from app.api.deps import AdminUser, SessionDep
from app.schemas.admin import (
    AdminDocumentRow,
    ApproveResponse,
    RejectRequest,
    RejectResponse,
)
from app.services.admin_service import AdminService

router = APIRouter()


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
