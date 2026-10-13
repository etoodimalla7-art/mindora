"""Shared FastAPI dependencies."""
from __future__ import annotations

import uuid
from collections.abc import AsyncGenerator
from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ForbiddenError, UnauthorizedError
from app.core.security import decode_token
from app.db.session import get_session as _get_session
from app.repositories.user_repo import UserRepository


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async for s in _get_session():
        yield s


SessionDep = Annotated[AsyncSession, Depends(get_session)]

_bearer = HTTPBearer(auto_error=False)


async def get_current_user_id(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> uuid.UUID:
    if credentials is None:
        raise UnauthorizedError("Authentication required.")
    payload = decode_token(credentials.credentials, expected_type="access")
    sub = payload.get("sub")
    if not sub:
        raise UnauthorizedError("Invalid token.")
    return uuid.UUID(sub)


async def get_current_user(
    session: SessionDep,
    user_id: Annotated[uuid.UUID, Depends(get_current_user_id)],
):
    repo = UserRepository(session)
    user = await repo.get_by_id(user_id)
    if not user or not user.is_active:
        raise UnauthorizedError("Account not found or disabled.")
    return user


async def get_admin_user(
    user: Annotated[object, Depends(get_current_user)],
):
    """Dependency that ensures the current user is an admin."""
    if not getattr(user, "is_admin", False):
        raise ForbiddenError("Administrator privileges required.")
    return user


CurrentUser = Annotated[object, Depends(get_current_user)]
CurrentUserId = Annotated[uuid.UUID, Depends(get_current_user_id)]
AdminUser = Annotated[object, Depends(get_admin_user)]
