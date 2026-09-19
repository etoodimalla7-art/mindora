from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.modules.documents.repository import DocumentsRepository
from api.modules.quizzes.repository import QuizzesRepository
from api.modules.quizzes.schemas import (
    AttemptResultOut, GenerateQuizIn, QuestionOut, QuestionResultOut, QuizOut, SubmitAttemptIn,
)
from api.modules.quizzes.service import QuizzesService
from api.modules.users.models import User

router = APIRouter(prefix="/quizzes", tags=["quizzes"])


def get_service(db: AsyncSession = Depends(get_db)) -> QuizzesService:
    return QuizzesService(QuizzesRepository(db), DocumentsRepository(db))


@router.post("/generate")
async def generate(
    payload: GenerateQuizIn,
    current_user: User = Depends(get_current_user),
    service: QuizzesService = Depends(get_service),
):
    quiz, questions = await service.generate(str(current_user.id), payload)
    return envelope(data=QuizOut(
        id=str(quiz.id), topic_title=quiz.topic_title, difficulty=quiz.difficulty,
        questions=[QuestionOut(id=str(q.id), q_type=q.q_type, prompt=q.prompt, choices=q.choices) for q in questions],
    ).model_dump())


@router.get("/{quiz_id}")
async def get_quiz(
    quiz_id: str,
    current_user: User = Depends(get_current_user),
    service: QuizzesService = Depends(get_service),
):
    quiz, questions = await service.get_quiz_for_taking(quiz_id, str(current_user.id))
    return envelope(data=QuizOut(
        id=str(quiz.id), topic_title=quiz.topic_title, difficulty=quiz.difficulty,
        questions=[QuestionOut(id=str(q.id), q_type=q.q_type, prompt=q.prompt, choices=q.choices) for q in questions],
    ).model_dump())


@router.post("/{quiz_id}/attempt")
async def submit_attempt(
    quiz_id: str,
    payload: SubmitAttemptIn,
    current_user: User = Depends(get_current_user),
    service: QuizzesService = Depends(get_service),
):
    attempt, results = await service.submit_attempt(quiz_id, str(current_user.id), payload.answers)
    return envelope(data=AttemptResultOut(
        attempt_id=str(attempt.id), score=attempt.score,
        results=[QuestionResultOut(**r) for r in results],
    ).model_dump())


@router.get("/{quiz_id}/results/{attempt_id}")
async def get_results(
    quiz_id: str,
    attempt_id: str,
    current_user: User = Depends(get_current_user),
    service: QuizzesService = Depends(get_service),
):
    attempt, results = await service.get_attempt_results(attempt_id, str(current_user.id))
    return envelope(data=AttemptResultOut(
        attempt_id=str(attempt.id), score=attempt.score,
        results=[QuestionResultOut(**r) for r in results],
    ).model_dump())
