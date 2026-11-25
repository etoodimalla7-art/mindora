"""Email provider factory."""
from __future__ import annotations

from app.core.config import settings
from app.integrations.email.provider import EmailProvider
from app.integrations.email.smtp import SMTPProvider


def get_email_provider(name: str | None = None) -> EmailProvider:
    provider = (name or settings.EMAIL_PROVIDER).lower()

    if provider == "smtp":
        return SMTPProvider()

    # Future: resend
    # if provider == "resend":
    #     from app.integrations.email.resend import ResendProvider
    #     return ResendProvider()

    # Fallback: log-only via SMTP (no credentials = logs)
    return SMTPProvider()
