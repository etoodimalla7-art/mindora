from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.catalog.models import Course, Subject, Topic


class CatalogRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_subjects(self, education_system: str | None, level: str | None) -> list[Subject]:
        query = select(Subject)
        if education_system:
            query = query.where(Subject.education_system == education_system)
        if level:
            query = query.where(Subject.level == level)
        result = await self.db.execute(query.order_by(Subject.name))
        return list(result.scalars().all())

    async def get_subject_by_name(self, name: str) -> Subject | None:
        result = await self.db.execute(select(Subject).where(Subject.name == name))
        return result.scalar_one_or_none()

    async def get_or_create_subject_by_name(self, name: str, education_system: str, level: str) -> Subject:
        """Feeds admin document approval (Phase 16): an approved exam
        paper's subject may not exist in the catalog yet — create it
        rather than blocking approval on a missing catalog entry."""
        existing = await self.get_subject_by_name(name)
        if existing:
            return existing
        subject = Subject(name=name, education_system=education_system, level=level)
        self.db.add(subject)
        await self.db.commit()
        await self.db.refresh(subject)
        return subject

    async def list_topics_for_course(self, course_id: str) -> list[Topic]:
        result = await self.db.execute(
            select(Topic).where(Topic.course_id == to_uuid(course_id)).order_by(Topic.order_index)
        )
        return list(result.scalars().all())

    async def list_topics_for_subject(self, subject_id: str) -> list[Topic]:
        """Used by the planner (Phase 7): finds the first course under
        this subject and returns its topics in order. A subject with no
        course/topics yet returns [] — callers fall back to a generic
        review session rather than failing plan generation."""
        course_result = await self.db.execute(
            select(Course).where(Course.subject_id == to_uuid(subject_id)).limit(1)
        )
        course = course_result.scalar_one_or_none()
        if not course:
            return []
        return await self.list_topics_for_course(str(course.id))
