from api.core.errors import NotFoundError
from api.modules.past_papers.repository import PastPapersRepository
from api.modules.past_papers.schemas import PastPaperOut


def _row_to_out(row, bookmarked_ids: set[str]) -> PastPaperOut:
    return PastPaperOut(
        id=str(row.id),
        title=row.title,
        level=row.level,
        year=row.year,
        session=row.session,
        subject_name=row.subject_name,
        examination_name=row.examination_name,
        country=row.country,
        system=row.system,
        is_bookmarked=str(row.id) in bookmarked_ids,
    )


class PastPapersService:
    def __init__(self, repo: PastPapersRepository):
        self.repo = repo

    async def search(self, user_id: str | None, **filters) -> list[PastPaperOut]:
        rows = await self.repo.search(**filters)
        bookmarked_ids = await self.repo.get_bookmarked_ids(user_id, [str(r.id) for r in rows]) if user_id else set()
        return [_row_to_out(r, bookmarked_ids) for r in rows]

    async def get_filters(self):
        return await self.repo.get_filters()

    async def bookmark(self, user_id: str, past_paper_id: str) -> None:
        await self.repo.add_bookmark(user_id, past_paper_id)

    async def unbookmark(self, user_id: str, past_paper_id: str) -> None:
        await self.repo.remove_bookmark(user_id, past_paper_id)

    async def list_bookmarked(self, user_id: str) -> list[PastPaperOut]:
        rows = await self.repo.list_bookmarked(user_id)
        ids = [str(r.id) for r in rows]
        return [_row_to_out(r, set(ids)) for r in rows]

    async def download(self, user_id: str, past_paper_id: str, credits_service, has_active_subscription: bool):
        """
        Section 29: the credit-gated action. Spends a credit (unless
        subscribed) BEFORE recording the download, so a failed payment
        never results in a download the student didn't pay for.
        `document_id` may be None for past papers without a linked
        file yet (real files arrive via the admin approval workflow,
        Phase 16) — the caller surfaces that as "not available yet"
        rather than a broken download link.
        """
        row = await self.repo.get_one(past_paper_id)
        if not row:
            raise NotFoundError("We couldn't find this past paper.")
        await credits_service.spend_for_download(user_id, "past_paper", past_paper_id, has_active_subscription)
        return row
