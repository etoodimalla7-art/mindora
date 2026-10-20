"""OTP service — generate, send, verify 6-digit codes."""
from __future__ import annotations

import logging
import secrets
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.errors import AppError, NotFoundError
from app.integrations.email.factory import get_email_provider
from app.integrations.email.provider import EmailMessage
from app.models.otp_code import OTPCode
from app.models.user import User

logger = logging.getLogger(__name__)


def _generate_code() -> str:
    """Generate a 6-digit code (cryptographically random)."""
    return f"{secrets.randbelow(1_000_000):06d}"


async def send_otp(
    session: AsyncSession,
    *,
    email: str,
    purpose: str = "verify_email",
) -> None:
    """Generate + send an OTP code to the given email.

    Rate limit: no more than one unverified code per OTP_RATE_LIMIT_SECONDS.
    """
    email = email.strip().lower()

    # Find user (must exist)
    stmt = select(User).where(User.email == email)
    user = (await session.execute(stmt)).scalar_one_or_none()
    if user is None:
        # Don't reveal whether the email exists (security best practice)
        # But log it.
        logger.info("otp_send_unknown_email: %s", email)
        return

    # Rate limit: check last code
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(seconds=settings.OTP_RATE_LIMIT_SECONDS)

    last_stmt = (
        select(OTPCode)
        .where(
            OTPCode.user_id == user.id,
            OTPCode.purpose == purpose,
            OTPCode.used.is_(False),
            OTPCode.created_at >= cutoff,
        )
        .order_by(OTPCode.created_at.desc())
        .limit(1)
    )
    last = (await session.execute(last_stmt)).scalar_one_or_none()
    if last is not None:
        remaining = int((last.created_at - cutoff).total_seconds())
        raise AppError(
            f"Please wait {max(remaining, 1)} seconds before requesting a new code.",
            code="otp_rate_limited",
            status_code=429,
        )

    # Invalidate previous unused codes for this purpose
    invalidate_stmt = (
        select(OTPCode)
        .where(
            OTPCode.user_id == user.id,
            OTPCode.purpose == purpose,
            OTPCode.used.is_(False),
        )
    )
    for old in (await session.execute(invalidate_stmt)).scalars().all():
        old.used = True

    # Generate new code
    code = _generate_code()
    expires_at = now + timedelta(minutes=settings.OTP_EXPIRES_MINUTES)

    otp = OTPCode(
        user_id=user.id,
        email=email,
        code=code,
        purpose=purpose,
        expires_at=expires_at,
        used=False,
        attempts=0,
    )
    session.add(otp)
    await session.commit()

    # Send email
    await _send_otp_email(email, code, purpose)

    logger.info("otp_sent email=%s purpose=%s", email, purpose)


async def _send_otp_email(email: str, code: str, purpose: str) -> None:
    """Send the OTP code via the configured email provider."""
    provider = get_email_provider()

    subject_map = {
        "verify_email": "Verify your MINDORA account",
        "reset_password": "Reset your MINDORA password",
    }
    subject = subject_map.get(purpose, "Your MINDORA verification code")

    html = f"""
    <!DOCTYPE html>
    <html>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f8fafc; padding: 40px 20px; margin: 0;">
      <div style="max-width: 480px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 16px rgba(0,0,0,0.06);">
        <div style="text-align: center; margin-bottom: 32px;">
          <h1 style="color: #0f172a; font-size: 24px; font-weight: 700; margin: 0;">MINDORA</h1>
        </div>

        <h2 style="color: #0f172a; font-size: 20px; font-weight: 600; margin: 0 0 12px;">Your verification code</h2>
        <p style="color: #64748b; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
          Enter this code to verify your email. It expires in {settings.OTP_EXPIRES_MINUTES} minutes.
        </p>

        <div style="background: #6366f1; border-radius: 12px; padding: 24px; text-align: center; margin: 0 0 24px;">
          <p style="color: white; font-size: 36px; font-weight: 700; letter-spacing: 8px; margin: 0; font-family: 'Courier New', monospace;">{code}</p>
        </div>

        <p style="color: #94a3b8; font-size: 13px; line-height: 1.6; margin: 0;">
          If you didn't request this code, you can safely ignore this email.
        </p>
      </div>
    </body>
    </html>
    """

    text = f"Your MINDORA verification code is: {code}\n\nIt expires in {settings.OTP_EXPIRES_MINUTES} minutes.\n\nIf you didn't request this code, ignore this email."

    await provider.send(
        EmailMessage(
            to=email,
            subject=subject,
            html=html,
            text=text,
        )
    )


async def verify_otp(
    session: AsyncSession,
    *,
    email: str,
    code: str,
    purpose: str = "verify_email",
) -> User:
    """Verify the code. Marks it used and the user verified."""
    email = email.strip().lower()
    code = code.strip()

    # Find user
    stmt = select(User).where(User.email == email)
    user = (await session.execute(stmt)).scalar_one_or_none()
    if user is None:
        raise NotFoundError("User not found.")

    # Find latest unused OTP for this purpose
    otp_stmt = (
        select(OTPCode)
        .where(
            OTPCode.user_id == user.id,
            OTPCode.purpose == purpose,
            OTPCode.used.is_(False),
        )
        .order_by(OTPCode.created_at.desc())
        .limit(1)
    )
    otp = (await session.execute(otp_stmt)).scalar_one_or_none()
    if otp is None:
        raise AppError(
            "No active code. Please request a new one.",
            code="otp_not_found",
            status_code=400,
        )

    now = datetime.now(timezone.utc)

    # Check expiry
    if otp.expires_at < now:
        otp.used = True
        await session.commit()
        raise AppError(
            "This code has expired. Please request a new one.",
            code="otp_expired",
            status_code=400,
        )

    # Check attempts
    if otp.attempts >= settings.OTP_MAX_ATTEMPTS:
        otp.used = True
        await session.commit()
        raise AppError(
            "Too many attempts. Please request a new code.",
            code="otp_max_attempts",
            status_code=429,
        )

    # Check code
    if not secrets.compare_digest(otp.code, code):
        otp.attempts += 1
        await session.commit()
        remaining = settings.OTP_MAX_ATTEMPTS - otp.attempts
        raise AppError(
            f"Invalid code. {remaining} attempt(s) remaining.",
            code="otp_invalid",
            status_code=400,
        )

    # Success
    otp.used = True
    if purpose == "verify_email":
        user.is_verified = True
    await session.commit()
    await session.refresh(user)

    logger.info("otp_verified email=%s purpose=%s", email, purpose)
    return user
