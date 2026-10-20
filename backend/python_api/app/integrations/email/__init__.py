from app.integrations.email.factory import get_email_provider
from app.integrations.email.provider import EmailMessage, EmailProvider, EmailResult

__all__ = ["EmailMessage", "EmailProvider", "EmailResult", "get_email_provider"]
