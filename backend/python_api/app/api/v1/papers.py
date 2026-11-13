"""Public past papers endpoints."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, Query
from fastapi.responses import StreamingResponse

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.admin import PaperRow
from app.services.admin_service import AdminService

router = APIRouter()


@router.get("", response_model=list[PaperRow])
async def list_papers(
    session: SessionDep,
    _user_id: CurrentUserId,
    subject: str | None = Query(default=None),
    exam_system: str | None = Query(default=None),
    exam_level: str | None = Query(default=None),
    exam_year: int | None = Query(default=None),
    search: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[PaperRow]:
    """List all published papers, optionally filtered."""
    return await AdminService(session).list_papers(
        subject=subject,
        exam_system=exam_system,
        exam_level=exam_level,
        exam_year=exam_year,
        search=search,
        limit=limit,
        offset=offset,
    )


@router.get("/{paper_id}/download")
async def download_paper(
    paper_id: uuid.UUID,
    session: SessionDep,
    _user_id: CurrentUserId,
) -> StreamingResponse:
    """Stream the PDF file for download."""
    file_data, file_name, mime_type = await AdminService(
        session
    ).get_paper_file(paper_id)

    return StreamingResponse(
        iter([file_data]),
        media_type=mime_type,
        headers={
            "Content-Disposition": f'attachment; filename="{file_name}"',
        },
    )
