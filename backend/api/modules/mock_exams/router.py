from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.modules.documents.repository import DocumentsRepository
from api.modules.mock_exams.repository import MockExamsRepository
from api.modules.mock_exams.schemas import (
    CreateMockExamIn, MockExamOut, MockExamResultOut, MockExamSectionOut, SubmitMockExamIn,
)
from api.modules.mock_exams.service import MockExamsService
from api.modules.quizzes.repository import QuizzesRepository
from api.modules.quizzes.schemas import QuestionOut, QuestionResultOut
from api.modules.users.models import User

router = APIRouter(prefix="/mock-exams", tags=["mock-exams"])


def get_service(db: AsyncSession = Depends(get_db)) -> MockExamsService:
    return MockExamsService(MockExamsRepository(db), QuizzesRepository(db), DocumentsRepository(db))


def _exam_out(mock_exam, sections) -> dict:
    return MockExamOut(
        id=str(mock_exam.id), subject_names=mock_exam.subject_names, difficulty=mock_exam.difficulty,
        duration_minutes=mock_exam.duration_minutes, status=mock_exam.status,
        sections=[
            MockExamSectionOut(
                subject_name=subject_name, quiz_id=quiz_id,
                questions=[QuestionOut(id=str(q.id), q_type=q.q_type, prompt=q.prompt, choices=q.choices) for q in questions],
            )
            for subject_name, quiz_id, questions in sections
        ],
    ).model_dump()


@router.post("")
async def create(
    payload: CreateMockExamIn,
    current_user: User = Depends(get_current_user),
    service: MockExamsService = Depends(get_service),
):
    mock_exam, sections = await service.create(str(current_user.id), payload)
    return envelope(data=_exam_out(mock_exam, sections))


@router.get("/{mock_exam_id}")
async def get_mock_exam(
    mock_exam_id: str,
    current_user: User = Depends(get_current_user),
    service: MockExamsService = Depends(get_service),
):
    mock_exam, sections = await service.get_for_taking(mock_exam_id, str(current_user.id))
    return envelope(data=_exam_out(mock_exam, sections))


@router.post("/{mock_exam_id}/submit")
async def submit(
    mock_exam_id: str,
    payload: SubmitMockExamIn,
    current_user: User = Depends(get_current_user),
    service: MockExamsService = Depends(get_service),
):
    attempt, section_scores, results = await service.submit(mock_exam_id, str(current_user.id), payload.answers)
    return envelope(data=MockExamResultOut(
        attempt_id=str(attempt.id), score=attempt.score, section_scores=section_scores,
        results=[QuestionResultOut(**r) for r in results],
    ).model_dump())


@router.get("/{mock_exam_id}/results")
async def get_results(
    mock_exam_id: str,
    current_user: User = Depends(get_current_user),
    service: MockExamsService = Depends(get_service),
):
    attempt, results = await service.get_latest_results(mock_exam_id, str(current_user.id))
    return envelope(data=MockExamResultOut(
        attempt_id=str(attempt.id), score=attempt.score, section_scores=attempt.section_scores,
        results=[QuestionResultOut(**r) for r in results],
    ).model_dump())
