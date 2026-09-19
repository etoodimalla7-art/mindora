from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.errors import ForbiddenError, UnauthorizedError
from api.core.ids import to_uuid
from api.core.security import decode_token
from api.modules.users.models import User
from sqlalchemy import select


async def get_current_user(
    authorization: str | None = Header(default=None),
    db: AsyncSession = Depends(get_db),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise UnauthorizedError("Please sign in to continue.")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = decode_token(token)
    except Exception as exc:
        raise UnauthorizedError("Session expired. Please sign in again.") from exc
    if payload.get("type") != "access":
        raise UnauthorizedError("Please sign in again.")
    try:
        user_uuid = to_uuid(payload["sub"])
    except Exception as exc:
        raise UnauthorizedError("Session expired. Please sign in again.") from exc
    result = await db.execute(select(User).where(User.id == user_uuid))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise UnauthorizedError("This account is not available.")
    return user


async def get_current_admin_user(current_user: User = Depends(get_current_user)) -> User:
    """Section 64: gates every admin endpoint. Nothing in this codebase
    sets role='admin' automatically — that has to be done directly in
    the database (or a future admin-invite flow), which is a deliberate
    safeguard against accidentally shipping an easy privilege-escalation
    path."""
    if current_user.role != "admin":
        raise ForbiddenError("You don't have permission to access this area.")
    return current_user
