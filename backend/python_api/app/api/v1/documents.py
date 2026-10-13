"""Document routes: upload, submit, read, list."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, File, Form, UploadFile, status

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.document import (
    DocumentDetail,
    DocumentOut,
    DocumentStatusOut,
    SubmitDocumentRequest,
)
from app.services.document_service import DocumentService

router = APIRouter()


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


@router.get("", response_model=list[DocumentOut])
async def list_my_documents(
    session: SessionDep, user_id: CurrentUserId
) -> list[DocumentOut]:
    return await DocumentService(session).list_mine(user_id)


@router.get("/{doc_id}", response_model=DocumentDetail)
async def get_document(
    doc_id: uuid.UUID, session: SessionDep, user_id: CurrentUserId
) -> DocumentDetail:
    return await DocumentService(session).get(user_id, doc_id)


@router.get("/{doc_id}/status", response_model=DocumentStatusOut)
async def get_document_status(
    doc_id: uuid.UUID, session: SessionDep, user_id: CurrentUserId
) -> DocumentStatusOut:
    return await DocumentService(session).get_status(user_id, doc_id)
