from sqlalchemy import select, distinct
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.catalog.models import Subject
from api.modules.past_papers.models import Examination, PastPaper, PastPaperBookmark


class PastPapersRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    def _base_query(self):
        return (
            select(
                PastPaper.id,
                PastPaper.title,
                PastPaper.level,
                PastPaper.year,
                PastPaper.session,
                PastPaper.document_id,
                Subject.name.label("subject_name"),
                Examination.name.label("examination_name"),
                Examination.country,
                Examination.system,
            )
            .join(Examination, PastPaper.examination_id == Examination.id)
            .join(Subject, PastPaper.subject_id == Subject.id)
        )

    async def search(
        self,
        *,
        country: str | None = None,
        system: str | None = None,
        level: str | None = None,
        subject_name: str | None = None,
        year: int | None = None,
        query_text: str | None = None,
        limit: int = 50,
    ) -> list:
        query = self._base_query()
        if country:
            query = query.where(Examination.country == country)
        if system:
            query = query.where(Examination.system == system)
        if level:
            query = query.where(PastPaper.level == level)
        if subject_name:
            query = query.where(Subject.name == subject_name)
        if year:
            query = query.where(PastPaper.year == year)
        if query_text:
            query = query.where(PastPaper.title.ilike(f"%{query_text}%"))
        query = query.order_by(Examination.country, Examination.system, PastPaper.year.desc()).limit(limit)
        result = await self.db.execute(query)
        return result.all()

    async def get_one(self, past_paper_id: str):
        result = await self.db.execute(self._base_query().where(PastPaper.id == to_uuid(past_paper_id)))
        return result.first()

    async def get_bookmarked_ids(self, user_id: str, past_paper_ids: list[str]) -> set[str]:
        if not past_paper_ids:
            return set()
        result = await self.db.execute(
            select(PastPaperBookmark.past_paper_id)
            .where(PastPaperBookmark.user_id == to_uuid(user_id))
            .where(PastPaperBookmark.past_paper_id.in_([to_uuid(pid) for pid in past_paper_ids]))
        )
        return {str(row[0]) for row in result.all()}

    async def get_filters(self) -> dict:
        countries = await self.db.execute(select(distinct(Examination.country)).order_by(Examination.country))
        systems = await self.db.execute(select(distinct(Examination.system)).order_by(Examination.system))
        levels = await self.db.execute(select(distinct(PastPaper.level)).order_by(PastPaper.level))
        subjects = await self.db.execute(select(distinct(Subject.name)).order_by(Subject.name))
        years = await self.db.execute(select(distinct(PastPaper.year)).order_by(PastPaper.year.desc()))
        return {
            "countries": [r[0] for r in countries.all()],
            "systems": [r[0] for r in systems.all()],
            "levels": [r[0] for r in levels.all()],
            "subjects": [r[0] for r in subjects.all()],
            "years": [r[0] for r in years.all()],
        }

    async def add_bookmark(self, user_id: str, past_paper_id: str) -> None:
        uid, pid = to_uuid(user_id), to_uuid(past_paper_id)
        existing = await self.db.execute(
            select(PastPaperBookmark)
            .where(PastPaperBookmark.user_id == uid)
            .where(PastPaperBookmark.past_paper_id == pid)
        )
        if existing.scalar_one_or_none():
            return
        self.db.add(PastPaperBookmark(user_id=uid, past_paper_id=pid))
        await self.db.commit()

    async def remove_bookmark(self, user_id: str, past_paper_id: str) -> None:
        result = await self.db.execute(
            select(PastPaperBookmark)
            .where(PastPaperBookmark.user_id == to_uuid(user_id))
            .where(PastPaperBookmark.past_paper_id == to_uuid(past_paper_id))
        )
        bookmark = result.scalar_one_or_none()
        if bookmark:
            await self.db.delete(bookmark)
            await self.db.commit()

    async def list_bookmarked(self, user_id: str) -> list:
        query = self._base_query().join(
            PastPaperBookmark, PastPaperBookmark.past_paper_id == PastPaper.id
        ).where(PastPaperBookmark.user_id == to_uuid(user_id))
        result = await self.db.execute(query)
        return result.all()

    # --- Admin/moderation (Phase 16) ---

    async def get_or_create_examination(self, country: str, system: str, name: str) -> Examination:
        result = await self.db.execute(
            select(Examination)
            .where(Examination.country == country)
            .where(Examination.system == system)
            .where(Examination.name == name)
        )
        existing = result.scalar_one_or_none()
        if existing:
            return existing
        examination = Examination(country=country, system=system, name=name)
        self.db.add(examination)
        await self.db.commit()
        await self.db.refresh(examination)
        return examination

    async def create_past_paper(
        self, examination_id: str, subject_id: str, document_id: str,
        title: str, level: str, year: int, session: str | None,
    ) -> PastPaper:
        """Closes the Phase 6 gap: an approved exam-flagged document
        becomes a real, downloadable past paper linked to its file,
        instead of the dev-seed-only papers with no document_id."""
        paper = PastPaper(
            examination_id=to_uuid(examination_id), subject_id=to_uuid(subject_id),
            document_id=to_uuid(document_id), title=title, level=level, year=year, session=session,
        )
        self.db.add(paper)
        await self.db.commit()
        await self.db.refresh(paper)
        return paper
