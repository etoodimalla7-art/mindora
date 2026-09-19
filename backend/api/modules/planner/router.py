from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.modules.catalog.repository import CatalogRepository
from api.modules.planner.repository import PlannerRepository
from api.modules.planner.schemas import CreateExamPlanIn, CreateSubjectPlanIn, StudyPlanOut, RescheduleOut
from api.modules.planner.service import PlannerService
from api.modules.study_sessions.schemas import StudySessionOut
from api.modules.users.models import User

router = APIRouter(prefix="/planner", tags=["planner"])


def get_service(db: AsyncSession = Depends(get_db)) -> PlannerService:
    return PlannerService(PlannerRepository(db), CatalogRepository(db))


def _plan_out(plan, session_count: int) -> dict:
    return StudyPlanOut(
        id=str(plan.id), mode=plan.mode, target_exam_name=plan.target_exam_name,
        subjects=plan.subjects, start_date=plan.start_date, end_date=plan.end_date,
        status=plan.status, session_count=session_count,
    ).model_dump()


@router.post("/exam-plan")
async def create_exam_plan(
    payload: CreateExamPlanIn,
    current_user: User = Depends(get_current_user),
    service: PlannerService = Depends(get_service),
):
    plan, sessions = await service.create_exam_plan(str(current_user.id), payload)
    return envelope(data=_plan_out(plan, len(sessions)))


@router.post("/subject-plan")
async def create_subject_plan(
    payload: CreateSubjectPlanIn,
    current_user: User = Depends(get_current_user),
    service: PlannerService = Depends(get_service),
):
    plan, sessions = await service.create_subject_plan(str(current_user.id), payload)
    return envelope(data=_plan_out(plan, len(sessions)))


@router.get("/plans/{plan_id}")
async def get_plan(
    plan_id: str,
    current_user: User = Depends(get_current_user),
    service: PlannerService = Depends(get_service),
):
    plan = await service.get_plan(plan_id, str(current_user.id))
    sessions = await service.repo.list_sessions_for_plan(plan_id)
    return envelope(data=_plan_out(plan, len(sessions)))


@router.get("/plans/{plan_id}/sessions")
async def get_sessions(
    plan_id: str,
    current_user: User = Depends(get_current_user),
    service: PlannerService = Depends(get_service),
):
    sessions = await service.get_sessions(plan_id, str(current_user.id))
    return envelope(data=[StudySessionOut.model_validate(orm_to_dict(s)).model_dump() for s in sessions])


@router.patch("/plans/{plan_id}/reschedule")
async def reschedule(
    plan_id: str,
    current_user: User = Depends(get_current_user),
    service: PlannerService = Depends(get_service),
):
    count = await service.reschedule(plan_id, str(current_user.id))
    return envelope(data=RescheduleOut(rescheduled_count=count).model_dump())
