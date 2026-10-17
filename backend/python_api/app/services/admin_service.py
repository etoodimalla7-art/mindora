"""Admin service — documents moderation + users + papers + stats."""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.models.document import (
    DOC_STATUS_APPROVED,
    DOC_STATUS_REJECTED,
    DOC_STATUS_UNDER_REVIEW,
    Document,
)
from app.models.paper import (
    ALLOWED_PAPER_EXTENSIONS,
    ALLOWED_PAPER_MIME_TYPES,
    MAX_PAPER_SIZE_BYTES,
    PAPER_STATUS_DRAFT,
    PAPER_STATUS_PUBLISHED,
    Paper,
)
from app.models.plan import StudySession
from app.models.user import User
from app.schemas.admin import (
    ActivityStats,
    AdminDocumentRow,
    AdminStatsOut,
    AdminUserRow,
    ApproveResponse,
    DocumentsStats,
    PaperDetail,
    PaperRow,
    PapersStats,
    PromoteResponse,
    RejectResponse,
    ToggleActiveResponse,
    UsersStats,
)


class AdminService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Documents (existing) ----------

    async def list_documents(
        self, status_filter: str | None, limit: int
    ) -> list[AdminDocumentRow]:
        stmt = select(Document).order_by(Document.created_at.desc()).limit(limit)
        if status_filter:
            stmt = stmt.where(Document.status == status_filter)
        rows = (await self.session.execute(stmt)).scalars().all()
        return [
            AdminDocumentRow(
                id=d.id,
                title=d.title,
                owner_email=getattr(d, "owner", None)
                and getattr(d.owner, "email", "")
                or "",
                status=d.status,
                created_at=d.created_at,
            )
            for d in rows
        ]

    async def approve(self, doc_id: uuid.UUID) -> ApproveResponse:
        doc = await self.session.get(Document, doc_id)
        if not doc:
            raise NotFoundError("Document not found.")
        doc.status = DOC_STATUS_APPROVED
        await self.session.commit()
        return ApproveResponse(id=doc.id, status=doc.status)

    async def reject(self, doc_id: uuid.UUID, reason: str) -> RejectResponse:
        doc = await self.session.get(Document, doc_id)
        if not doc:
            raise NotFoundError("Document not found.")
        doc.status = DOC_STATUS_REJECTED
        meta = dict(doc.metadata_json or {})
        meta["rejection_reason"] = reason
        doc.metadata_json = meta
        await self.session.commit()
        return RejectResponse(id=doc.id, status=doc.status, reason=reason)

    # ---------- Stats ----------

    async def get_stats(self) -> AdminStatsOut:
        now = datetime.now(timezone.utc)
        week_ago = now - timedelta(days=7)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

        users_total = await self._count(User)
        users_active = await self._count(User, User.is_active.is_(True))
        users_admins = await self._count(User, User.is_admin.is_(True))
        users_new_week = await self._count(User, User.created_at >= week_ago)

        docs_total = await self._count(Document)
        docs_pending = await self._count(
            Document, Document.status == DOC_STATUS_UNDER_REVIEW
        )
        docs_approved = await self._count(
            Document, Document.status == DOC_STATUS_APPROVED
        )

        papers_total = await self._count(Paper)
        papers_published = await self._count(
            Paper, Paper.status == PAPER_STATUS_PUBLISHED
        )
        papers_draft = await self._count(Paper, Paper.status == PAPER_STATUS_DRAFT)

        sessions_today = await self._count(
            StudySession, StudySession.created_at >= today_start
        )
        uploads_today = await self._count(
            Document, Document.created_at >= today_start
        )

        return AdminStatsOut(
            users=UsersStats(
                total=users_total,
                active=users_active,
                admins=users_admins,
                new_this_week=users_new_week,
            ),
            documents=DocumentsStats(
                total=docs_total, pending=docs_pending, approved=docs_approved
            ),
            papers=PapersStats(
                total=papers_total, published=papers_published, draft=papers_draft
            ),
            activity=ActivityStats(
                sessions_today=sessions_today, uploads_today=uploads_today
            ),
        )

    async def _count(self, model, *where) -> int:
        stmt = select(func.count(model.id))
        for w in where:
            stmt = stmt.where(w)
        return int((await self.session.execute(stmt)).scalar() or 0)

    # ---------- Users ----------

    async def list_users(
        self, search: str | None, limit: int, offset: int
    ) -> list[AdminUserRow]:
        stmt = select(User).order_by(User.created_at.desc()).limit(limit).offset(offset)
        if search:
            like = f"%{search.lower()}%"
            stmt = stmt.where(
                (func.lower(User.email).like(like))
                | (func.lower(User.full_name).like(like))
            )
        rows = (await self.session.execute(stmt)).scalars().all()
        return [
            AdminUserRow(
                id=u.id,
                email=u.email,
                full_name=u.full_name,
                is_active=u.is_active,
                is_verified=u.is_verified,
                is_admin=u.is_admin,
                created_at=u.created_at,
                last_login_at=u.last_login_at,
            )
            for u in rows
        ]

    async def toggle_user_active(self, user_id: uuid.UUID) -> ToggleActiveResponse:
        user = await self.session.get(User, user_id)
        if not user:
            raise NotFoundError("User not found.")
        user.is_active = not user.is_active
        await self.session.commit()
        return ToggleActiveResponse(id=user.id, is_active=user.is_active)

    async def promote_user(self, user_id: uuid.UUID) -> PromoteResponse:
        user = await self.session.get(User, user_id)
        if not user:
            raise NotFoundError("User not found.")
        user.is_admin = True
        await self.session.commit()
        return PromoteResponse(id=user.id, is_admin=user.is_admin)

    # ---------- Papers ----------

    async def create_paper(
        self,
        uploader_id: uuid.UUID,
        *,
        title: str,
        subject: str,
        exam_system: str,
        exam_level: str,
        exam_year: int | None,
        language: str,
        description: str | None,
        file_name: str,
        file_data: bytes,
        mime_type: str,
    ) -> PaperDetail:
        # Validation: extension + MIME + size
        name_lower = file_name.lower()
        if not any(name_lower.endswith(ext) for ext in ALLOWED_PAPER_EXTENSIONS):
            raise ValidationError(
                f"File extension not allowed. Use one of: {ALLOWED_PAPER_EXTENSIONS}"
            )
        if mime_type not in ALLOWED_PAPER_MIME_TYPES:
            raise ValidationError(
                f"MIME type not allowed. Use one of: {ALLOWED_PAPER_MIME_TYPES}"
            )
        if len(file_data) > MAX_PAPER_SIZE_BYTES:
            raise ValidationError(
                f"File too large ({len(file_data)} bytes). Max is {MAX_PAPER_SIZE_BYTES}."
            )

        paper = Paper(
            uploader_id=uploader_id,
            title=title,
            description=description,
            subject=subject,
            exam_system=exam_system,
            exam_level=exam_level,
            exam_year=exam_year,
            language=language,
            file_data=file_data,
            file_name=file_name,
            file_size=len(file_data),
            mime_type=mime_type,
            status=PAPER_STATUS_PUBLISHED,
        )
        self.session.add(paper)
        await self.session.commit()
        await self.session.refresh(paper)
        return self._to_detail(paper)

    async def list_papers(
        self, subject: str | None, limit: int, offset: int
    ) -> list[PaperRow]:
        stmt = select(Paper).order_by(Paper.created_at.desc()).limit(limit).offset(offset)
        if subject:
            stmt = stmt.where(Paper.subject == subject)
        rows = (await self.session.execute(stmt)).scalars().all()
        return [PaperRow.model_validate(p) for p in rows]

    async def get_paper(self, paper_id: uuid.UUID) -> PaperDetail:
        paper = await self.session.get(Paper, paper_id)
        if not paper:
            raise NotFoundError("Paper not found.")
        return self._to_detail(paper)

    async def delete_paper(self, paper_id: uuid.UUID) -> None:
        paper = await self.session.get(Paper, paper_id)
        if not paper:
            raise NotFoundError("Paper not found.")
        await self.session.delete(paper)
        await self.session.commit()

    def _to_detail(self, p: Paper) -> PaperDetail:
        return PaperDetail(
            id=p.id,
            title=p.title,
            description=p.description,
            subject=p.subject,
            exam_system=p.exam_system,
            exam_level=p.exam_level,
            exam_year=p.exam_year,
            language=p.language,
            status=p.status,
            file_name=p.file_name,
            file_size=p.file_size,
            mime_type=p.mime_type,
            download_count=p.download_count,
            created_at=p.created_at,
            uploader_id=p.uploader_id,
        )
