"""Auth routes — stubs wired to services in Phase 3.

For Phase 1 we expose the routes so the API surface is stable, but each
endpoint returns a clean 501 until the service layer lands.
"""
from __future__ import annotations

from fastapi import APIRouter, status

from app.core.errors import AppError
from app.schemas.auth import AuthResponse, LoginRequest, RefreshRequest, RegisterRequest

router = APIRouter()


def _not_implemented() -> None:
    raise AppError(
        "Authentication is not yet available in this build.",
        code="not_implemented",
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
    )


@router.post("/register", response_model=AuthResponse)
async def register(_: RegisterRequest) -> AuthResponse:
    _not_implemented()
    raise AssertionError  # unreachable, kept for type-checkers


@router.post("/login", response_model=AuthResponse)
async def login(_: LoginRequest) -> AuthResponse:
    _not_implemented()
    raise AssertionError


@router.post("/refresh", response_model=AuthResponse)
async def refresh(_: RefreshRequest) -> AuthResponse:
    _not_implemented()
    raise AssertionError


@router.post("/logout")
async def logout() -> dict:
    _not_implemented()
    raise AssertionError
