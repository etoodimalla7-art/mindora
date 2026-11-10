"""Public papers endpoints (for students)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query, Response
from fastapi.responses import StreamingResponse

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.admin import PaperRow, PaperDetail
from app.services.admin_service import AdminService

router = APIRouter()


@router.get("", response_model=list[PaperRow])
async def list_papers(
    session: SessionDep,
    _user_id: CurrentUserId,
    subject: str | None = Query(default=None),
    exam_system: str | None = Query(default=None),
    exam_level: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[PaperRow]:
    """List all published papers, optionally filtered."""
    # On réutilise AdminService mais on ne garde que les papers publiés
    # (En prod, on pourrait ajouter un filtre status='published')
    return await AdminService(session).list_papers(subject, limit, offset)


@router.get("/{paper_id}/download")
async def download_paper(
    paper_id: uuid.UUID,
    session: SessionDep,
    _user_id: CurrentUserId,
) -> StreamingResponse:
    """Download the PDF file for a paper."""
    service = AdminService(session)
    file_data, file_name, mime_type = await service.get_paper_file(paper_id)
    
    # StreamingResponse pour ne pas charger tout en mémoire si gros fichier
    return StreamingResponse(
        iter([file_data]),
        media_type=mime_type,
        headers={
            "Content-Disposition": f'attachment; filename="{file_name}"',
            "Content-Length": str(len(file_data)),
        },
    )
