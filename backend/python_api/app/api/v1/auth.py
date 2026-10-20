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


# ---------------------------------------------------------------------------
# Email OTP (Batch 1.2)
# ---------------------------------------------------------------------------
from pydantic import BaseModel, EmailStr, Field  # noqa: E402

from app.services.otp_service import send_otp, verify_otp  # noqa: E402


class SendOtpRequest(BaseModel):
    email: EmailStr
    purpose: str = Field(default="verify_email", pattern="^(verify_email|reset_password)$")


class SendOtpResponse(BaseModel):
    status: str
    message: str


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern="^[0-9]{6}$")
    purpose: str = Field(default="verify_email", pattern="^(verify_email|reset_password)$")


class VerifyOtpResponse(BaseModel):
    status: str
    is_verified: bool
    message: str


@router.post("/send-otp", response_model=SendOtpResponse)
async def send_otp_endpoint(
    payload: SendOtpRequest,
    session: SessionDep,
) -> SendOtpResponse:
    """Send a 6-digit OTP code to the given email (verify_email or reset_password)."""
    await send_otp(session, email=payload.email, purpose=payload.purpose)
    return SendOtpResponse(
        status="sent",
        message=f"Code sent to {payload.email}. Check your inbox (and spam).",
    )


@router.post("/verify-otp", response_model=VerifyOtpResponse)
async def verify_otp_endpoint(
    payload: VerifyOtpRequest,
    session: SessionDep,
) -> VerifyOtpResponse:
    """Verify a 6-digit OTP code. On success, marks the user as verified (for verify_email)."""
    user = await verify_otp(
        session,
        email=payload.email,
        code=payload.code,
        purpose=payload.purpose,
    )
    return VerifyOtpResponse(
        status="verified",
        is_verified=user.is_verified,
        message="Email verified successfully." if payload.purpose == "verify_email" else "Code verified.",
    )


