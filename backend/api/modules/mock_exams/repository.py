from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.mock_exams.models import MockExam, MockExamAttempt, MockExamSection


class MockExamsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_mock_exam(
        self, owner_id: str, subject_names: list[str], difficulty: str, duration_minutes: int
    ) -> MockExam:
        exam = MockExam(
            owner_id=to_uuid(owner_id), subject_names=subject_names,
            difficulty=difficulty, duration_minutes=duration_minutes, status="active",
        )
        self.db.add(exam)
        await self.db.commit()
        await self.db.refresh(exam)
        return exam

    async def add_section(self, mock_exam_id: str, subject_name: str, quiz_id: str) -> MockExamSection:
        section = MockExamSection(
            mock_exam_id=to_uuid(mock_exam_id), subject_name=subject_name, quiz_id=to_uuid(quiz_id),
        )
        self.db.add(section)
        await self.db.commit()
        await self.db.refresh(section)
        return section

    async def get_owned(self, mock_exam_id: str, owner_id: str) -> MockExam | None:
        result = await self.db.execute(
            select(MockExam)
            .where(MockExam.id == to_uuid(mock_exam_id))
            .where(MockExam.owner_id == to_uuid(owner_id))
        )
        return result.scalar_one_or_none()

    async def list_sections(self, mock_exam_id: str) -> list[MockExamSection]:
        result = await self.db.execute(
            select(MockExamSection).where(MockExamSection.mock_exam_id == to_uuid(mock_exam_id))
        )
        return list(result.scalars().all())

    async def create_attempt(
        self, mock_exam_id: str, user_id: str, score: float, section_scores: dict, answers: dict,
        started_at: datetime, ended_at: datetime,
    ) -> MockExamAttempt:
        attempt = MockExamAttempt(
            mock_exam_id=to_uuid(mock_exam_id), user_id=to_uuid(user_id), score=score,
            section_scores=section_scores, answers=answers, started_at=started_at, ended_at=ended_at,
        )
        self.db.add(attempt)
        await self.db.commit()
        await self.db.refresh(attempt)
        return attempt

    async def get_latest_attempt(self, mock_exam_id: str, user_id: str) -> MockExamAttempt | None:
        result = await self.db.execute(
            select(MockExamAttempt)
            .where(MockExamAttempt.mock_exam_id == to_uuid(mock_exam_id))
            .where(MockExamAttempt.user_id == to_uuid(user_id))
            .order_by(MockExamAttempt.ended_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def list_attempts_for_user(self, user_id: str) -> list[MockExamAttempt]:
        """Feeds progress analytics (Phase 12): every mock-exam attempt
        this user has ever submitted, across all exams."""
        result = await self.db.execute(
            select(MockExamAttempt).where(MockExamAttempt.user_id == to_uuid(user_id))
        )
        return list(result.scalars().all())
