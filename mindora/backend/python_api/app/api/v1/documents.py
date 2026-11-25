"""Document routes: upload, submit, read, list, download, library."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, File, Form, Query, Request, UploadFile, status
from fastapi.responses import StreamingResponse
from sqlalchemy import or_, select

from app.api.deps import CurrentUserId, SessionDep
from app.core.errors import ForbiddenError, NotFoundError
from app.models.credit import Download
from app.models.document import DOC_STATUS_APPROVED, Document
from app.repositories.document_repo import DocumentRepository
from app.schemas.credit import DownloadOut, DownloadResponse
from app.schemas.document import (
    DocumentDetail,
    DocumentOut,
    DocumentStatusOut,
    SubmitDocumentRequest,
)
from app.services.credit_service import CreditService
from app.services.document_service import DocumentService

router = APIRouter()


# ---------------------------------------------------------------
# Static routes must be declared BEFORE dynamic /{doc_id} routes.
# ---------------------------------------------------------------


@router.get("/library", response_model=list[DocumentOut])
async def library(
    session: SessionDep,
    _user_id: CurrentUserId,
    category: str | None = Query(default=None),
    academic_level: str | None = Query(default=None),
    language: str | None = Query(default=None),
    search: str | None = Query(default=None),
    limit: int = Query(default=100, ge=1, le=500),
) -> list[DocumentOut]:
    """List approved documents from all users with optional filters."""
    stmt = select(Document).where(
        Document.status == DOC_STATUS_APPROVED,
        Document.deleted_at.is_(None),
    )
    if category:
        stmt = stmt.where(Document.category.ilike(f"%{category.strip()}%"))
    if academic_level:
        stmt = stmt.where(
            Document.academic_level.ilike(f"%{academic_level.strip()}%")
        )
    if language:
        stmt = stmt.where(Document.language == language.strip().lower())
    if search:
        pattern = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Document.title.ilike(pattern),
                Document.description.ilike(pattern),
                Document.category.ilike(pattern),
            )
        )
    stmt = stmt.order_by(Document.created_at.desc()).limit(limit)
    rows = (await session.execute(stmt)).scalars().all()
    return [DocumentOut.model_validate(d) for d in rows]


@router.post(
    "/upload",
    response_model=DocumentOut,
    status_code=status.HTTP_201_CREATED,
)
async def upload_document(
    session: SessionDep,
    user_id: CurrentUserId,
    file: UploadFile = File(...),
    title: str = Form(..., min_length=3, max_length=200),
    description: str = Form(..., min_length=1),
) -> DocumentOut:
    content = await file.read()
    return await DocumentService(session).upload(
        owner_id=user_id,
        filename=file.filename or "document",
        mime_type=file.content_type or "application/octet-stream",
        content=content,
        title=title,
        description=description,
    )


@router.post("/{doc_id}/submit", response_model=DocumentDetail)
async def submit_document(
    doc_id: uuid.UUID,
    payload: SubmitDocumentRequest,
    session: SessionDep,
    user_id: CurrentUserId,
) -> DocumentDetail:
    return await DocumentService(session).submit(
        owner_id=user_id,
        doc_id=doc_id,
        payload=payload,
    )


@router.post("/{doc_id}/download", response_model=DownloadResponse)
async def download_document(
    doc_id: uuid.UUID,
    request: Request,
    session: SessionDep,
    user_id: CurrentUserId,
) -> DownloadResponse:
    """Download a document. Owners download for free; others pay 1 credit."""
    doc = await DocumentRepository(session).get(doc_id)
    if not doc:
        raise NotFoundError("Document not found.")

    svc = CreditService(session)
    download = await svc.spend_download(
        user_id=user_id,
        document=doc,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )
    await session.commit()
    remaining = await svc.balance(user_id)
    return DownloadResponse(
        download=DownloadOut.model_validate(download),
        remaining_balance=remaining,
    )


@router.get("/{doc_id}/file")
async def download_document_file(
    doc_id: uuid.UUID,
    session: SessionDep,
    user_id: CurrentUserId,
) -> StreamingResponse:
    """Stream document binary content after ownership or recorded Download."""
    doc = await DocumentRepository(session).get(doc_id)
    if not doc:
        raise NotFoundError("Document not found.")

    if doc.owner_id != user_id:
        dl = (
            await session.execute(
                select(Download.id)
                .where(
                    Download.document_id == doc_id,
                    Download.user_id == user_id,
                )
                .limit(1)
            )
        ).scalar_one_or_none()
        if dl is None:
            raise ForbiddenError(
                "Please unlock this document download first."
            )

    payload = bytes(doc.content or b"")
    return StreamingResponse(
        iter([payload]),
        media_type=doc.mime_type or "application/octet-stream",
        headers={
            "Content-Disposition": (
                f'attachment; filename="{doc.original_filename}"'
            ),
        },
    )


@router.get("/{doc_id}/status", response_model=DocumentStatusOut)
async def get_document_status(
    doc_id: uuid.UUID, session: SessionDep, user_id: CurrentUserId
) -> DocumentStatusOut:
    return await DocumentService(session).get_status(user_id, doc_id)


@router.get("/{doc_id}", response_model=DocumentDetail)
async def get_document(
    doc_id: uuid.UUID, session: SessionDep, user_id: CurrentUserId
) -> DocumentDetail:
    return await DocumentService(session).get(user_id, doc_id)


@router.get("", response_model=list[DocumentOut])
async def list_my_documents(
    session: SessionDep, user_id: CurrentUserId
) -> list[DocumentOut]:
    return await DocumentService(session).list_mine(user_id)
