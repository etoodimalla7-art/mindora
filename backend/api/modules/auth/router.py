from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.errors import envelope
from api.core.rate_limit import AUTH_WRITE_LIMIT, LOGIN_LIMIT, limiter
from api.integrations.email_provider import get_email_provider
from api.modules.auth.repository import AuthRepository
from api.modules.auth.schemas import (
    RegisterRequest,
    LoginRequest,
    RefreshRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
)
from api.modules.auth.service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


def get_service(db: AsyncSession = Depends(get_db)) -> AuthService:
    return AuthService(AuthRepository(db), get_email_provider())


@router.post("/register")
@limiter.limit(AUTH_WRITE_LIMIT)
async def register(request: Request, payload: RegisterRequest, service: AuthService = Depends(get_service)):
    tokens = await service.register(payload)
    return envelope(data=tokens.model_dump())


@router.post("/login")
@limiter.limit(LOGIN_LIMIT)
async def login(request: Request, payload: LoginRequest, service: AuthService = Depends(get_service)):
    tokens = await service.login(payload)
    return envelope(data=tokens.model_dump())


@router.post("/refresh")
async def refresh(payload: RefreshRequest, service: AuthService = Depends(get_service)):
    tokens = await service.refresh(payload.refresh_token)
    return envelope(data=tokens.model_dump())


@router.post("/logout")
async def logout():
    # Stateless JWTs: logout is client-side (discard tokens). A token
    # denylist can be added here later if immediate server-side
    # revocation becomes a requirement.
    return envelope(data={"success": True})


@router.post("/password/forgot")
@limiter.limit(AUTH_WRITE_LIMIT)
async def forgot_password(
    request: Request, payload: ForgotPasswordRequest, service: AuthService = Depends(get_service)
):
    await service.forgot_password(payload.email)
    # Same response whether or not the account exists (see service note).
    return envelope(data={"message": "If that email exists, a reset link was sent."})


@router.post("/password/reset")
async def reset_password(
    payload: ResetPasswordRequest, service: AuthService = Depends(get_service)
):
    await service.reset_password(payload.reset_token, payload.new_password)
    return envelope(data={"message": "Password updated. Please sign in."})
