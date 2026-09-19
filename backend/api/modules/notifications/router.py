from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.modules.flashcards.repository import FlashcardsRepository
from api.modules.notifications.repository import NotificationsRepository
from api.modules.notifications.schemas import (
    NotificationOut, NotificationPreferencesOut, UpdateNotificationPreferencesIn,
)
from api.modules.notifications.service import NotificationsService
from api.modules.planner.repository import PlannerRepository
from api.modules.quizzes.repository import QuizzesRepository
from api.modules.study_sessions.repository import StudySessionsRepository
from api.modules.users.models import User

router = APIRouter(prefix="/notifications", tags=["notifications"])


def get_service(db: AsyncSession = Depends(get_db)) -> NotificationsService:
    return NotificationsService(
        NotificationsRepository(db), StudySessionsRepository(db), PlannerRepository(db),
        QuizzesRepository(db), FlashcardsRepository(db),
    )


@router.get("")
async def list_notifications(
    current_user: User = Depends(get_current_user),
    service: NotificationsService = Depends(get_service),
):
    notifications = await service.list_notifications(str(current_user.id))
    return envelope(data=[NotificationOut.model_validate(orm_to_dict(n)).model_dump() for n in notifications])


@router.patch("/{notification_id}/read")
async def mark_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    service: NotificationsService = Depends(get_service),
):
    notification = await service.mark_read(notification_id, str(current_user.id))
    return envelope(data={"success": notification is not None})


@router.get("/preferences")
async def get_preferences(
    current_user: User = Depends(get_current_user),
    service: NotificationsService = Depends(get_service),
):
    prefs = await service.get_preferences(str(current_user.id))
    return envelope(data=NotificationPreferencesOut.model_validate(prefs).model_dump())


@router.put("/preferences")
async def update_preferences(
    payload: UpdateNotificationPreferencesIn,
    current_user: User = Depends(get_current_user),
    service: NotificationsService = Depends(get_service),
):
    prefs = await service.update_preferences(
        str(current_user.id), payload.model_dump(exclude_none=True),
    )
    return envelope(data=NotificationPreferencesOut.model_validate(prefs).model_dump())
