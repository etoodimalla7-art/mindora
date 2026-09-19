from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.modules.flashcards.repository import FlashcardsRepository
from api.modules.mock_exams.repository import MockExamsRepository
from api.modules.progress.schemas import DashboardOverviewOut, ProgressOut, ReadinessScoreOut
from api.modules.progress.service import ProgressService
from api.modules.quizzes.repository import QuizzesRepository
from api.modules.study_sessions.repository import StudySessionsRepository
from api.modules.users.models import User

router = APIRouter(prefix="/progress", tags=["progress"])


def get_service(db: AsyncSession = Depends(get_db)) -> ProgressService:
    return ProgressService(
        StudySessionsRepository(db), QuizzesRepository(db), FlashcardsRepository(db), MockExamsRepository(db),
    )


@router.get("/overview")
async def overview(
    current_user: User = Depends(get_current_user),
    service: ProgressService = Depends(get_service),
):
    data = await service.get_overview(str(current_user.id))
    out = DashboardOverviewOut(
        streak_days=data["streak_days"],
        subjects=[ProgressOut.model_validate(s) for s in data["subjects"]],
        weakest_subject=data["weakest_subject"],
    )
    return envelope(data=out.model_dump())


@router.get("/readiness/{target_exam_name}")
async def readiness(
    target_exam_name: str,
    current_user: User = Depends(get_current_user),
    service: ProgressService = Depends(get_service),
):
    data = await service.get_readiness(str(current_user.id), target_exam_name)
    return envelope(data=ReadinessScoreOut.model_validate(data).model_dump())
