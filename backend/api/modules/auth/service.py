from api.core.errors import ValidationFailedError, UnauthorizedError
from api.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    create_reset_token,
    decode_token,
)
from api.integrations.email_provider import EmailProvider
from api.modules.auth.repository import AuthRepository
from api.modules.auth.schemas import RegisterRequest, LoginRequest, TokenPair


class AuthService:
    def __init__(self, repo: AuthRepository, email_provider: EmailProvider):
        self.repo = repo
        self.email_provider = email_provider

    async def register(self, payload: RegisterRequest) -> TokenPair:
        existing = await self.repo.get_by_email(payload.email)
        if existing:
            raise ValidationFailedError("An account with this email already exists.")
        user = await self.repo.create_user(
            payload.email, hash_password(payload.password), payload.locale
        )
        return TokenPair(
            access_token=create_access_token(str(user.id)),
            refresh_token=create_refresh_token(str(user.id)),
        )

    async def login(self, payload: LoginRequest) -> TokenPair:
        user = await self.repo.get_by_email(payload.email)
        if not user or not verify_password(payload.password, user.password_hash):
            raise UnauthorizedError("Incorrect email or password.")
        return TokenPair(
            access_token=create_access_token(str(user.id)),
            refresh_token=create_refresh_token(str(user.id)),
        )

    async def refresh(self, refresh_token: str) -> TokenPair:
        try:
            payload = decode_token(refresh_token)
        except Exception as exc:
            raise UnauthorizedError("Session expired. Please sign in again.") from exc
        if payload.get("type") != "refresh":
            raise UnauthorizedError("Session expired. Please sign in again.")
        user_id = payload["sub"]
        return TokenPair(
            access_token=create_access_token(user_id),
            refresh_token=create_refresh_token(user_id),
        )

    async def forgot_password(self, email: str) -> None:
        user = await self.repo.get_by_email(email)
        # Always behave the same whether or not the account exists, so the
        # endpoint can't be used to enumerate registered emails.
        if user:
            reset_token = create_reset_token(str(user.id))
            await self.email_provider.send_password_reset(email, reset_token)

    async def reset_password(self, reset_token: str, new_password: str) -> None:
        try:
            payload = decode_token(reset_token)
        except Exception as exc:
            raise ValidationFailedError(
                "This reset link is invalid or has expired."
            ) from exc
        if payload.get("type") != "reset":
            raise ValidationFailedError("This reset link is invalid or has expired.")
        user = await self.repo.get_by_id(payload["sub"])
        if not user:
            raise ValidationFailedError("This reset link is invalid or has expired.")
        await self.repo.update_password(user, hash_password(new_password))
