from fastapi import APIRouter, Depends, UploadFile, File, Request
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.core.rate_limit import UPLOAD_LIMIT, limiter
from api.integrations.storage_provider import get_storage_provider
from api.modules.documents.repository import DocumentsRepository
from api.modules.documents.schemas import DocumentOut, DocumentMetadataIn, DocumentExamMetadataIn, DocumentStatusOut
from api.modules.documents.service import DocumentsService
from api.modules.users.models import User

router = APIRouter(prefix="/documents", tags=["documents"])


def get_service(db: AsyncSession = Depends(get_db)) -> DocumentsService:
    return DocumentsService(DocumentsRepository(db), get_storage_provider())


@router.post("/upload")
@limiter.limit(UPLOAD_LIMIT)
async def upload(
    request: Request,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    service: DocumentsService = Depends(get_service),
):
    content = await file.read()
    doc = await service.upload(str(current_user.id), file.filename, content)
    return envelope(data=DocumentOut.model_validate(orm_to_dict(doc)).model_dump())


@router.post("/{document_id}/metadata")
async def save_metadata(
    document_id: str,
    payload: DocumentMetadataIn,
    current_user: User = Depends(get_current_user),
    service: DocumentsService = Depends(get_service),
):
    doc = await service.save_metadata(document_id, str(current_user.id), payload)
    return envelope(data=DocumentOut.model_validate(orm_to_dict(doc)).model_dump())


@router.post("/{document_id}/exam-metadata")
async def save_exam_metadata(
    document_id: str,
    payload: DocumentExamMetadataIn,
    current_user: User = Depends(get_current_user),
    service: DocumentsService = Depends(get_service),
):
    await service.save_exam_metadata(document_id, str(current_user.id), payload)
    return envelope(data={"success": True})


@router.post("/{document_id}/submit")
async def submit(
    document_id: str,
    current_user: User = Depends(get_current_user),
    service: DocumentsService = Depends(get_service),
):
    doc, problems, warnings = await service.submit(document_id, str(current_user.id))
    return envelope(data=DocumentStatusOut(status=doc.status, problems=problems, warnings=warnings).model_dump())


@router.get("/{document_id}/status")
async def status(
    document_id: str,
    current_user: User = Depends(get_current_user),
    service: DocumentsService = Depends(get_service),
):
    doc = await service.get_status(document_id, str(current_user.id))
    return envelope(data=DocumentStatusOut(status=doc.status).model_dump())


@router.get("/mine")
async def list_mine(
    current_user: User = Depends(get_current_user),
    service: DocumentsService = Depends(get_service),
):
    docs = await service.list_mine(str(current_user.id))
    return envelope(data=[DocumentOut.model_validate(orm_to_dict(d)).model_dump() for d in docs])
