"""
Email provider interface (section: Replaceability Matrix). Swap the
implementation without touching any service code — e.g. plug in SES,
SendGrid, or a local SMTP relay behind this same interface.
"""
from abc import ABC, abstractmethod


class EmailProvider(ABC):
    @abstractmethod
    async def send_password_reset(self, to_email: str, reset_token: str) -> None:
        ...


class ConsoleEmailProvider(EmailProvider):
    """Dev-only stub: logs instead of sending. Replace in production."""

    async def send_password_reset(self, to_email: str, reset_token: str) -> None:
        print(f"[email:dev-stub] password reset for {to_email} — token={reset_token}")


def get_email_provider() -> EmailProvider:
    # Later: branch on settings.email_provider to return a real adapter.
    return ConsoleEmailProvider()
