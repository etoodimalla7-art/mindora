"""Authentication service: registration, login, refresh, logout."""
from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, UnauthorizedError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.repositories.session_repo import SessionRepository
from app.repositories.user_repo import UserRepository
from app.schemas.auth import AuthResponse, TokenPair
from app.services.credit_service import CreditService


class AuthService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.users = UserRepository(session)
        self.sessions = SessionRepository(session)

    async def register(
        self,
        *,
        email: str,
        password: str,
        full_name: str | None,
        preferred_language: str,
        country_code: str,
        user_agent: str | None = None,
        ip_address: str | None = None,
    ) -> AuthResponse:
        existing = await self.users.get_by_email(email)
        if existing:
            raise ConflictError("An account with this email already exists.")

        user = await self.users.create(
            email=email,
            hashed_password=hash_password(password),
            full_name=full_name,
            preferred_language=preferred_language,
            country_code=country_code,
        )

        # Bootstrap: promote to admin if no admin exists yet.
        admin_count_stmt = select(func.count(User.id)).where(User.is_admin.is_(True))
        admin_count = (await self.session.execute(admin_count_stmt)).scalar() or 0
        if admin_count == 0:
            user.is_admin = True

        # Grant the signup bonus.
        await CreditService(self.session).grant_signup_bonus(user.id)

        tokens = await self._issue_tokens(user, user_agent, ip_address)
        await self.session.commit()
        await self.session.refresh(user)
        return AuthResponse(tokens=tokens, user=user)  # type: ignore[arg-type]

    async def login(
        self,
        *,
        email: str,
        password: str,
        user_agent: str | None = None,
        ip_address: str | None = None,
    ) -> AuthResponse:
        user = await self.users.get_by_email(email)
        if not user or not verify_password(password, user.hashed_password):
            raise UnauthorizedError("Invalid email or password.")
        if not user.is_active:
            raise UnauthorizedError("This account is disabled.")

        await self.users.touch_last_login(user)
        tokens = await self._issue_tokens(user, user_agent, ip_address)
        await self.session.commit()
        await self.session.refresh(user)
        return AuthResponse(tokens=tokens, user=user)  # type: ignore[arg-type]

    async def refresh(
        self,
        *,
        refresh_token: str,
        user_agent: str | None = None,
        ip_address: str | None = None,
    ) -> AuthResponse:
        payload = decode_token(refresh_token, expected_type="refresh")
        subject = payload.get("sub")
        if not subject:
            raise UnauthorizedError("Invalid refresh token.")

        session_row = await self.sessions.get_active_by_token(refresh_token)
        if not session_row:
            raise UnauthorizedError("Refresh token is expired or revoked.")

        # Rotate: revoke all sessions with this hash, issue a new one.
        await self.sessions.revoke_all_by_token(refresh_token)

        import uuid

        user = await self.users.get_by_id(uuid.UUID(subject))
        if not user:
            raise UnauthorizedError("Account not found.")

        tokens = await self._issue_tokens(user, user_agent, ip_address)
        await self.session.commit()
        await self.session.refresh(user)
        return AuthResponse(tokens=tokens, user=user)  # type: ignore[arg-type]

    async def logout(self, *, refresh_token: str) -> None:
        """Revoke ALL sessions sharing this refresh token hash.

        Using `revoke_all_by_token` guarantees that even if the same
        refresh token was issued multiple times (e.g. rapid logins within
        the same second), none of them remain valid after logout.
        """
        await self.sessions.revoke_all_by_token(refresh_token)
        await self.session.commit()

    async def _issue_tokens(
        self,
        user: User,
        user_agent: str | None,
        ip_address: str | None,
    ) -> TokenPair:
        access = create_access_token(str(user.id))
        refresh = create_refresh_token(str(user.id))
        await self.sessions.create(
            user_id=user.id,
            refresh_token=refresh,
            user_agent=user_agent,
            ip_address=ip_address,
        )
        return TokenPair(access_token=access, refresh_token=refresh)
