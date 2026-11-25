"""Auth schemas."""
from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field

from app.schemas.user import UserOut


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = Field(default=None, max_length=120)
    preferred_language: str = Field(default="en", max_length=8)
    country_code: str = Field(default="CM", max_length=8)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class AuthResponse(BaseModel):
    tokens: TokenPair
    user: UserOut


class AdminLoginChallengeResponse(BaseModel):
    requires_2fa: bool = True
    challenge_token: str
    email: str
    message: str


class AdminTwoFactorVerifyRequest(BaseModel):
    challenge_token: str = Field(min_length=10)
    code: str = Field(min_length=6, max_length=6, pattern="^[0-9]{6}$")


class AdminTwoFactorResendRequest(BaseModel):
    challenge_token: str = Field(min_length=10)


class AdminAuthResponse(AuthResponse):
    permissions: list[str] = Field(default_factory=list)
    roles: list[str] = Field(default_factory=list)
    two_factor_verified: bool = True
