from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.ids import to_uuid
from api.modules.users.models import User


class AuthRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_email(self, email: str) -> User | None:
        result = await self.db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def get_by_id(self, user_id: str) -> User | None:
        result = await self.db.execute(select(User).where(User.id == to_uuid(user_id)))
        return result.scalar_one_or_none()

    async def create_user(self, email: str, password_hash: str, locale: str) -> User:
        user = User(email=email, password_hash=password_hash, locale=locale)
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def update_password(self, user: User, password_hash: str) -> None:
        user.password_hash = password_hash
        await self.db.commit()
