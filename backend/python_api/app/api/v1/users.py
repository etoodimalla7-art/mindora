"""User routes — me endpoint stub until Phase 3 auth lands."""
from __future__ import annotations

from fastapi import APIRouter, status

from app.core.errors import AppError
from app.schemas.user import UserOut, UserUpdate

router = APIRouter()


@router.get("/me", response_model=UserOut)
async def me() -> UserOut:
    raise AppError(
        "Not authenticated.",
        code="unauthorized",
        status_code=status.HTTP_401_UNAUTHORIZED,
    )


@router.patch("/me", response_model=UserOut)
async def update_me(_: UserUpdate) -> UserOut:
    raise AppError(
        "Not authenticated.",
        code="unauthorized",
        status_code=status.HTTP_401_UNAUTHORIZED,
    )
