from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.modules.study_sessions.repository import StudySessionsRepository
from api.modules.study_sessions.schemas import StudySessionOut
from api.modules.study_sessions.service import StudySessionsService
from api.modules.users.models import User

router = APIRouter(prefix="/study-sessions", tags=["study-sessions"])


def get_service(db: AsyncSession = Depends(get_db)) -> StudySessionsService:
    return StudySessionsService(StudySessionsRepository(db))


@router.get("/today")
async def today(
    current_user: User = Depends(get_current_user),
    service: StudySessionsService = Depends(get_service),
):
    sessions = await service.get_today(str(current_user.id))
    return envelope(data=[StudySessionOut.model_validate(orm_to_dict(s)).model_dump() for s in sessions])


@router.post("/{session_id}/start")
async def start(
    session_id: str,
    current_user: User = Depends(get_current_user),
    service: StudySessionsService = Depends(get_service),
):
    session = await service.start(session_id, str(current_user.id))
    return envelope(data=StudySessionOut.model_validate(orm_to_dict(session)).model_dump())


@router.post("/{session_id}/complete")
async def complete(
    session_id: str,
    current_user: User = Depends(get_current_user),
    service: StudySessionsService = Depends(get_service),
):
    session = await service.complete(session_id, str(current_user.id))
    return envelope(data=StudySessionOut.model_validate(orm_to_dict(session)).model_dump())


@router.post("/{session_id}/skip")
async def skip(
    session_id: str,
    current_user: User = Depends(get_current_user),
    service: StudySessionsService = Depends(get_service),
):
    session = await service.skip(session_id, str(current_user.id))
    return envelope(data=StudySessionOut.model_validate(orm_to_dict(session)).model_dump())
