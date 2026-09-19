from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.deps import get_current_user
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.modules.users.models import User
from api.modules.users.repository import UsersRepository
from api.modules.users.schemas import UserOut, EducationProfileIn, EducationProfileOut
from api.modules.users.service import UsersService

router = APIRouter(prefix="/users", tags=["users"])


def get_service(db: AsyncSession = Depends(get_db)) -> UsersService:
    return UsersService(UsersRepository(db))


@router.get("/me")
async def me(current_user: User = Depends(get_current_user)):
    return envelope(data=UserOut.model_validate(orm_to_dict(current_user)).model_dump())


@router.get("/me/education-profile")
async def get_education_profile(
    current_user: User = Depends(get_current_user),
    service: UsersService = Depends(get_service),
):
    profile = await service.get_education_profile(str(current_user.id))
    return envelope(data=EducationProfileOut.model_validate(profile).model_dump())


@router.put("/me/education-profile")
async def put_education_profile(
    payload: EducationProfileIn,
    current_user: User = Depends(get_current_user),
    service: UsersService = Depends(get_service),
):
    profile = await service.save_education_profile(str(current_user.id), payload)
    return envelope(data=EducationProfileOut.model_validate(profile).model_dump())
