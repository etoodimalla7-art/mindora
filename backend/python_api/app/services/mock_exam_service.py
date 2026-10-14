"""Mock exam orchestration service."""
from __future__ import annotations

import logging
import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, NotFoundError, ValidationError
from app.models.mock_exam import (
    MOCK_STATUS_DRAFT,
    MOCK_STATUS_GRADED,
    MOCK_STATUS_IN_PROGRESS,
    MOCK_STATUS_READY,
    MOCK_STATUS_SUBMITTED,
    MockAnswer,
    MockExam,
    MockQuestion,
)
from app.schemas.mock_exam import (
    AnswerResult,
    CreateMockExamRequest,
    MockExamDetail,
    MockExamOut,
    MockExamResults,
    SubmitAnswerRequest,
)
from ai.generators.question_generator import generate_questions

logger = logging.getLogger(__name__)


class MockExamService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Create ----------

    async def create(
        self, user_id: uuid.UUID, payload: CreateMockExamRequest
    ) -> MockExamDetail:
        # 1. Create the exam shell.
        exam = MockExam(
            user_id=user_id,
            title=payload.title,
            subject=payload.subject,
            academic_level=payload.academic_level,
            question_count=payload.question_count,
            duration_minutes=payload.duration_minutes,
            difficulty=payload.difficulty,
            source_document_ids=[str(x) for x in payload.source_document_ids],
            status=MOCK_STATUS_DRAFT,
        )
        self.session.add(exam)
        await self.session.flush()

        # 2. Generate questions via AI.
        generated = await generate_questions(
            self.session,
            user_id=user_id,
            subject=payload.subject,
            difficulty=payload.difficulty,
            count=payload.question_count,
            document_ids=payload.source_document_ids,
        )
        if not generated:
            await self.session.rollback()
            raise ValidationError(
                "We could not generate questions for this exam. "
                "Make sure you have at least one approved document on this "
                "subject, then try again."
            )

        # 3. Persist the questions.
        for q in generated:
            self.session.add(
                MockQuestion(
                    exam_id=exam.id,
                    position=q.position,
                    question_type=q.question_type,
                    prompt=q.prompt,
                    options=q.options,
                    correct_answer=q.correct_answer,
                    explanation=q.explanation,
                    difficulty=q.difficulty,
                    points=1,
                    metadata_json=q.metadata,
                )
            )

        exam.question_count = len(generated)
        exam.status = MOCK_STATUS_READY

        await self.session.commit()
        await self.session.refresh(exam)
        return await self._to_detail(exam, reveal_answers=False)

    # ---------- Start ----------

    async def start(self, user_id: uuid.UUID, exam_id: uuid.UUID) -> MockExamDetail:
        exam = await self._get(user_id, exam_id)
        if exam.status not in (MOCK_STATUS_READY, MOCK_STATUS_DRAFT):
            raise ConflictError(
                f"Cannot start an exam in status '{exam.status}'."
            )
        exam.status = MOCK_STATUS_IN_PROGRESS
        exam.started_at = datetime.now(UTC)
        await self.session.commit()
        await self.session.refresh(exam)
        return await self._to_detail(exam, reveal_answers=False)

    # ---------- Submit answer ----------

    async def submit_answer(
        self,
        user_id: uuid.UUID,
        exam_id: uuid.UUID,
        payload: SubmitAnswerRequest,
    ) -> MockExamDetail:
        exam = await self._get(user_id, exam_id)
        if exam.status != MOCK_STATUS_IN_PROGRESS:
            raise ConflictError("The exam is not in progress.")

        question = next(
            (q for q in exam.questions if q.id == payload.question_id), None
        )
        if not question:
            raise NotFoundError("Question not found in this exam.")

        # Upsert the answer.
        existing = next(
            (a for a in exam_answers(exam) if a.question_id == question.id),
            None,
        )
        if existing:
            existing.user_answer = payload.answer
            existing.time_spent_seconds = payload.time_spent_seconds
        else:
            self.session.add(
                MockAnswer(
                    exam_id=exam.id,
                    question_id=question.id,
                    user_answer=payload.answer,
                    time_spent_seconds=payload.time_spent_seconds,
                )
            )

        await self.session.commit()
        await self.session.refresh(exam)
        return await self._to_detail(exam, reveal_answers=False)

    # ---------- Submit (finalize + grade) ----------

    async def submit(
        self, user_id: uuid.UUID, exam_id: uuid.UUID
    ) -> MockExamResults:
        exam = await self._get(user_id, exam_id)
        if exam.status not in (MOCK_STATUS_IN_PROGRESS, MOCK_STATUS_SUBMITTED):
            raise ConflictError(
                f"Cannot submit an exam in status '{exam.status}'."
            )

        # Grade each answer.
        correct = 0
        wrong = 0
        skipped = 0
        for q in exam.questions:
            answer = next(
                (a for a in exam_answers(exam) if a.question_id == q.id), None
            )
            if answer is None:
                skipped += 1
                continue
            if not answer.user_answer:
                skipped += 1
                continue
            is_ok = _is_correct(q, answer.user_answer)
            answer.is_correct = is_ok
            answer.points_awarded = q.points if is_ok else 0
            if is_ok:
                correct += 1
            else:
                wrong += 1

        total = max(len(exam.questions), 1)
        score = round(100.0 * correct / total, 1)

        exam.status = MOCK_STATUS_GRADED
        exam.submitted_at = datetime.now(UTC)
        exam.graded_at = datetime.now(UTC)
        exam.score = score
        exam.correct_count = correct
        exam.wrong_count = wrong
        exam.skipped_count = skipped
        exam.feedback_summary = _build_summary(score, correct, wrong, skipped)

        await self.session.commit()
        await self.session.refresh(exam)
        return await self._to_results(exam)

    # ---------- Read ----------

    async def get(
        self, user_id: uuid.UUID, exam_id: uuid.UUID
    ) -> MockExamDetail:
        exam = await self._get(user_id, exam_id)
        reveal = exam.status in (MOCK_STATUS_GRADED,)
        return await self._to_detail(exam, reveal_answers=reveal)

    async def results(
        self, user_id: uuid.UUID, exam_id: uuid.UUID
    ) -> MockExamResults:
        exam = await self._get(user_id, exam_id)
        if exam.status != MOCK_STATUS_GRADED:
            raise ConflictError("The exam has not been graded yet.")
        return await self._to_results(exam)

    async def list_exams(self, user_id: uuid.UUID) -> list[MockExamOut]:
        stmt = (
            select(MockExam)
            .where(
                MockExam.user_id == user_id,
                MockExam.deleted_at.is_(None),
            )
            .order_by(MockExam.created_at.desc())
            .limit(50)
        )
        rows = (await self.session.execute(stmt)).scalars().all()
        return [MockExamOut.model_validate(r) for r in rows]

    # ---------- Internals ----------

    async def _get(self, user_id: uuid.UUID, exam_id: uuid.UUID) -> MockExam:
        stmt = select(MockExam).where(
            MockExam.id == exam_id,
            MockExam.user_id == user_id,
            MockExam.deleted_at.is_(None),
        )
        exam = (await self.session.execute(stmt)).scalar_one_or_none()
        if not exam:
            raise NotFoundError("Exam not found.")
        return exam

    async def _to_detail(
        self, exam: MockExam, *, reveal_answers: bool
    ) -> MockExamDetail:
        questions = []
        for q in exam.questions:
            data = {
                "id": q.id,
                "position": q.position,
                "question_type": q.question_type,
                "prompt": q.prompt,
                "options": q.options,
                "difficulty": q.difficulty,
                "points": q.points,
            }
            if reveal_answers:
                data["correct_answer"] = q.correct_answer
                data["explanation"] = q.explanation
            questions.append(data)

        return MockExamDetail(
            **MockExamOut.model_validate(exam).model_dump(),
            questions=questions,  # type: ignore[arg-type]
        )

    async def _to_results(self, exam: MockExam) -> MockExamResults:
        answers: list[AnswerResult] = []
        for q in exam.questions:
            a = next(
                (x for x in exam_answers(exam) if x.question_id == q.id), None
            )
            answers.append(
                AnswerResult(
                    question_id=q.id,
                    user_answer=a.user_answer if a else None,
                    is_correct=a.is_correct if a else None,
                    points_awarded=a.points_awarded if a else 0,
                    correct_answer=q.correct_answer,
                    explanation=q.explanation,
                    ai_feedback=a.ai_feedback if a else None,
                )
            )

        # Topic breakdown from question metadata
        topics: dict[str, dict[str, int]] = {}
        for q in exam.questions:
            topic = (q.metadata_json or {}).get("topic", "general")
            topics.setdefault(topic, {"total": 0, "correct": 0})
            topics[topic]["total"] += 1
            a = next(
                (x for x in exam_answers(exam) if x.question_id == q.id), None
            )
            if a and a.is_correct:
                topics[topic]["correct"] += 1

        return MockExamResults(
            **MockExamOut.model_validate(exam).model_dump(),
            answers=answers,
            feedback_summary=exam.feedback_summary,
            topic_breakdown=topics,
        )


# ---------- Helpers ----------


def exam_answers(exam: MockExam) -> list[MockAnswer]:
    """Return the answers attached to this exam.

    SQLAlchemy lazy loads from the relationship; we walk questions because
    answers are attached to questions in our schema.
    """
    collected: list[MockAnswer] = []
    for q in exam.questions:
        collected.extend(q.answers or [])
    return collected


def _is_correct(question: MockQuestion, user_answer: str) -> bool:
    ua = (user_answer or "").strip().lower()
    ca = (question.correct_answer or "").strip().lower()
    if question.question_type == "mcq":
        # Compare only the letter (A/B/C/D).
        return ua == ca or ua.startswith(ca)
    if question.question_type == "true_false":
        return ua == ca
    # short_answer: tolerant comparison — exact match or substring.
    return ua == ca or ca in ua or ua in ca


def _build_summary(score: float, correct: int, wrong: int, skipped: int) -> str:
    total = correct + wrong + skipped
    if score >= 80:
        mood = "Excellent work."
    elif score >= 60:
        mood = "Solid attempt."
    elif score >= 40:
        mood = "You are getting there."
    else:
        mood = "This topic needs more attention."
    return (
        f"{mood} You scored {score}% "
        f"({correct}/{total} correct, {wrong} wrong, {skipped} skipped)."
    )
