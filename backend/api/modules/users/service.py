from api.core.errors import NotFoundError
from api.modules.users.repository import UsersRepository
from api.modules.users.schemas import EducationProfileIn


class UsersService:
    def __init__(self, repo: UsersRepository):
        self.repo = repo

    async def get_education_profile(self, user_id: str):
        profile = await self.repo.get_education_profile(user_id)
        if not profile:
            raise NotFoundError("No education profile set up yet.")
        return profile

    async def save_education_profile(self, user_id: str, payload: EducationProfileIn):
        return await self.repo.upsert_education_profile(user_id, payload.model_dump())
