"""User routes."""
from __future__ import annotations

from fastapi import APIRouter

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.education import EducationProfileUpdate
from app.schemas.user import UserOut
from app.services.profile_service import ProfileService

router = APIRouter()


@router.get("/me", response_model=UserOut)
async def me(session: SessionDep, user_id: CurrentUserId) -> UserOut:
    user = await ProfileService(session).get_me(user_id)
    return UserOut.model_validate(user)


@router.put("/me/education", response_model=UserOut)
async def update_education(
    payload: EducationProfileUpdate, session: SessionDep, user_id: CurrentUserId
) -> UserOut:
    user = await ProfileService(session).update_education(user_id, payload)
    return UserOut.model_validate(user)
