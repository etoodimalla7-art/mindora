"""Auth routes."""
from __future__ import annotations

from fastapi import APIRouter, Request, Response, status

from app.api.deps import SessionDep
from app.schemas.auth import (
    AuthResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
)
from app.services.auth_service import AuthService

router = APIRouter()


def _client_meta(request: Request) -> tuple[str | None, str | None]:
    ua = request.headers.get("user-agent")
    ip = request.client.host if request.client else None
    return ua, ip


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, request: Request, session: SessionDep) -> AuthResponse:
    ua, ip = _client_meta(request)
    svc = AuthService(session)
    return await svc.register(
        email=payload.email,
        password=payload.password,
        full_name=payload.full_name,
        preferred_language=payload.preferred_language,
        country_code=payload.country_code,
        user_agent=ua,
        ip_address=ip,
    )


@router.post("/login", response_model=AuthResponse)
async def login(payload: LoginRequest, request: Request, session: SessionDep) -> AuthResponse:
    ua, ip = _client_meta(request)
    svc = AuthService(session)
    return await svc.login(
        email=payload.email,
        password=payload.password,
        user_agent=ua,
        ip_address=ip,
    )


@router.post("/refresh", response_model=AuthResponse)
async def refresh(payload: RefreshRequest, request: Request, session: SessionDep) -> AuthResponse:
    ua, ip = _client_meta(request)
    svc = AuthService(session)
    return await svc.refresh(refresh_token=payload.refresh_token, user_agent=ua, ip_address=ip)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(payload: RefreshRequest, session: SessionDep) -> Response:
    svc = AuthService(session)
    await svc.logout(refresh_token=payload.refresh_token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
