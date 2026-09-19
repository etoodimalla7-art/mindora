from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_admin_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.modules.admin.repository import AdminRepository
from api.modules.admin.schemas import (
    AnalyticsOverviewOut, ApproveResultOut, AuditLogEntryOut, RejectDocumentIn, ReviewQueueItemOut,
)
from api.modules.admin.service import AdminService
from api.modules.catalog.repository import CatalogRepository
from api.modules.credits.repository import CreditsRepository
from api.modules.credits.service import CreditsService
from api.modules.documents.repository import DocumentsRepository
from api.modules.past_papers.repository import PastPapersRepository
from api.modules.users.models import User
from api.modules.users.repository import UsersRepository

router = APIRouter(prefix="/admin", tags=["admin"])


def get_service(db: AsyncSession = Depends(get_db)) -> AdminService:
    return AdminService(
        DocumentsRepository(db), CatalogRepository(db), PastPapersRepository(db),
        CreditsService(CreditsRepository(db)), UsersRepository(db), AdminRepository(db),
    )


@router.get("/documents/queue")
async def review_queue(
    admin: User = Depends(get_current_admin_user),
    service: AdminService = Depends(get_service),
):
    items = await service.get_review_queue()
    out = []
    for doc, analysis, validations, exam_meta in items:
        summary = [f"{v.check_name}: {'pass' if v.passed else 'fail'}" + (f" ({v.detail})" if v.detail else "") for v in validations]
        out.append(ReviewQueueItemOut(
            id=str(doc.id), uploader_id=str(doc.uploader_id), title=doc.title, description=doc.description,
            category=doc.category, level=doc.level, language=doc.language, status=doc.status,
            detected_subject=analysis.detected_subject if analysis else None,
            detected_level=analysis.detected_level if analysis else None,
            detected_language=analysis.detected_language if analysis else None,
            quality_score=analysis.quality_score if analysis else None,
            duplicate_of_id=str(analysis.duplicate_of_id) if analysis and analysis.duplicate_of_id else None,
            similarity_score=analysis.similarity_score if analysis else None,
            is_exam=bool(exam_meta and exam_meta.is_exam),
            validation_summary=summary,
        ).model_dump())
    return envelope(data=out)


@router.post("/documents/{document_id}/approve")
async def approve(
    document_id: str,
    admin: User = Depends(get_current_admin_user),
    service: AdminService = Depends(get_service),
):
    doc, credits_awarded, past_paper_created = await service.approve(document_id, str(admin.id))
    return envelope(data=ApproveResultOut(
        document_id=str(doc.id), status=doc.status,
        credits_awarded=credits_awarded, past_paper_created=past_paper_created,
    ).model_dump())


@router.post("/documents/{document_id}/reject")
async def reject(
    document_id: str,
    payload: RejectDocumentIn,
    admin: User = Depends(get_current_admin_user),
    service: AdminService = Depends(get_service),
):
    doc = await service.reject(document_id, payload.reason, str(admin.id))
    return envelope(data={"document_id": str(doc.id), "status": doc.status})


@router.get("/analytics/overview")
async def analytics_overview(
    admin: User = Depends(get_current_admin_user),
    service: AdminService = Depends(get_service),
):
    data = await service.get_analytics_overview()
    return envelope(data=AnalyticsOverviewOut(**data).model_dump())


@router.get("/audit-log")
async def audit_log(
    admin: User = Depends(get_current_admin_user),
    service: AdminService = Depends(get_service),
):
    entries = await service.get_audit_log()
    return envelope(data=[AuditLogEntryOut.model_validate(orm_to_dict(e)).model_dump() for e in entries])
