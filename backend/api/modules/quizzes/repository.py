from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.quizzes.models import Question, Quiz, QuizAttempt


class QuizzesRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_quiz_with_questions(
        self, owner_id: str, topic_title: str, difficulty: str, source_document_id: str | None,
        questions_data: list[dict],
    ) -> tuple[Quiz, list[Question]]:
        quiz = Quiz(
            owner_id=to_uuid(owner_id), topic_title=topic_title, difficulty=difficulty,
            source_document_id=to_uuid(source_document_id) if source_document_id else None,
        )
        self.db.add(quiz)
        await self.db.flush()

        questions = [
            Question(
                quiz_id=quiz.id, q_type=q["type"], prompt=q["prompt"],
                choices=q["choices"], correct_answer=q["correct_answer"],
            )
            for q in questions_data
        ]
        self.db.add_all(questions)
        await self.db.commit()
        await self.db.refresh(quiz)
        for question in questions:
            await self.db.refresh(question)
        return quiz, questions

    async def get_owned_quiz(self, quiz_id: str, owner_id: str) -> Quiz | None:
        result = await self.db.execute(
            select(Quiz).where(Quiz.id == to_uuid(quiz_id)).where(Quiz.owner_id == to_uuid(owner_id))
        )
        return result.scalar_one_or_none()

    async def list_questions(self, quiz_id: str) -> list[Question]:
        result = await self.db.execute(select(Question).where(Question.quiz_id == to_uuid(quiz_id)))
        return list(result.scalars().all())

    async def create_attempt(
        self, quiz_id: str, user_id: str, score: float, answers: dict, started_at: datetime, ended_at: datetime
    ) -> QuizAttempt:
        attempt = QuizAttempt(
            quiz_id=to_uuid(quiz_id), user_id=to_uuid(user_id), score=score,
            answers=answers, started_at=started_at, ended_at=ended_at,
        )
        self.db.add(attempt)
        await self.db.commit()
        await self.db.refresh(attempt)
        return attempt

    async def get_owned_attempt(self, attempt_id: str, user_id: str) -> QuizAttempt | None:
        result = await self.db.execute(
            select(QuizAttempt)
            .where(QuizAttempt.id == to_uuid(attempt_id))
            .where(QuizAttempt.user_id == to_uuid(user_id))
        )
        return result.scalar_one_or_none()

    async def list_attempts_with_quiz_topic_for_user(self, owner_id: str) -> list[tuple[str, float]]:
        """Returns (topic_title, score) for every quiz attempt this user
        has made — feeds progress analytics (Phase 12) per-subject
        aggregation."""
        result = await self.db.execute(
            select(Quiz.topic_title, QuizAttempt.score)
            .join(QuizAttempt, QuizAttempt.quiz_id == Quiz.id)
            .where(QuizAttempt.user_id == to_uuid(owner_id))
        )
        return [(row[0], row[1]) for row in result.all()]
