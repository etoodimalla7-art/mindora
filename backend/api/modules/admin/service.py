from datetime import date

from api.core.errors import NotFoundError, ValidationFailedError
from api.modules.credits.rules import credits_from_new_approvals


class AdminService:
    """
    Sections 64-65: the document review queue. Deliberately composes
    the repositories from other modules (documents, catalog,
    past_papers, credits, users) rather than duplicating their logic —
    approving a document is exactly the moment two things this codebase
    has been building toward for several phases finally connect:
    Phase 15's contribution-credit bonus, and Phase 6's past papers
    getting a real linked file.
    """

    def __init__(self, documents_repo, catalog_repo, past_papers_repo, credits_service, users_repo, admin_repo=None):
        self.documents_repo = documents_repo
        self.catalog_repo = catalog_repo
        self.past_papers_repo = past_papers_repo
        self.credits_service = credits_service
        self.users_repo = users_repo
        self.admin_repo = admin_repo

    async def get_review_queue(self):
        documents = await self.documents_repo.list_for_review()
        items = []
        for doc in documents:
            analysis = await self.documents_repo.get_analysis(str(doc.id))
            validations = await self.documents_repo.list_validations(str(doc.id))
            exam_meta = await self.documents_repo.get_exam_metadata(str(doc.id))
            items.append((doc, analysis, validations, exam_meta))
        return items

    async def approve(self, document_id: str, admin_user_id: str | None = None):
        doc = await self.documents_repo.get_by_id(document_id)
        if not doc:
            raise NotFoundError("We couldn't find this document.")
        if doc.status == "Approved":
            raise ValidationFailedError("This document is already approved.")

        uploader_id = str(doc.uploader_id)
        previous_approved_count = await self.documents_repo.count_approved_for_user(uploader_id)
        await self.documents_repo.set_status(doc, "Approved")
        new_approved_count = previous_approved_count + 1

        credits_awarded = credits_from_new_approvals(previous_approved_count, new_approved_count)
        if credits_awarded > 0:
            await self.credits_service.grant(uploader_id, credits_awarded, "contribution_bonus", document_id)

        past_paper_created = False
        exam_meta = await self.documents_repo.get_exam_metadata(document_id)
        if exam_meta and exam_meta.is_exam:
            profile = await self.users_repo.get_education_profile(uploader_id)
            country = profile.country if profile else "Cameroon"
            subject_name = exam_meta.exam_subject or doc.category or "General"
            level = exam_meta.exam_level or doc.level or "Unspecified"
            system = exam_meta.exam_system or "Unspecified"

            subject = await self.catalog_repo.get_or_create_subject_by_name(subject_name, system, level)
            examination = await self.past_papers_repo.get_or_create_examination(
                country, system, exam_meta.exam_name or system,
            )
            await self.past_papers_repo.create_past_paper(
                str(examination.id), str(subject.id), document_id,
                doc.title or doc.original_filename, level,
                exam_meta.exam_year or date.today().year, exam_meta.exam_session,
            )
            past_paper_created = True

        if self.admin_repo and admin_user_id:
            await self.admin_repo.record_audit_log(
                admin_user_id, "document_approved", "document", document_id,
                {"credits_awarded": credits_awarded, "past_paper_created": past_paper_created},
            )

        return doc, credits_awarded, past_paper_created

    async def reject(self, document_id: str, reason: str, admin_user_id: str | None = None):
        doc = await self.documents_repo.get_by_id(document_id)
        if not doc:
            raise NotFoundError("We couldn't find this document.")
        await self.documents_repo.record_validation(document_id, "admin_rejection", False, reason)
        await self.documents_repo.set_status(doc, "Rejected")

        if self.admin_repo and admin_user_id:
            await self.admin_repo.record_audit_log(
                admin_user_id, "document_rejected", "document", document_id, {"reason": reason},
            )

        return doc

    async def get_audit_log(self, limit: int = 100):
        if not self.admin_repo:
            return []
        return await self.admin_repo.list_audit_log(limit)

    async def get_analytics_overview(self):
        total_users = await self.users_repo.count_all()
        documents_by_status = await self.documents_repo.count_by_status()
        return {"total_users": total_users, "documents_by_status": documents_by_status}
