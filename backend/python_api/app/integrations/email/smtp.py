"""SMTP email provider (Gmail dev / any SMTP)."""
from __future__ import annotations

import asyncio
import logging
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.core.config import settings
from app.integrations.email.provider import EmailMessage, EmailResult

logger = logging.getLogger(__name__)


class SMTPProvider:
    name = "smtp"

    def __init__(self) -> None:
        self.host = settings.SMTP_HOST
        self.port = settings.SMTP_PORT
        self.user = settings.SMTP_USER
        self.password = settings.SMTP_PASS
        self.from_addr = settings.EMAIL_FROM

    async def send(self, message: EmailMessage) -> EmailResult:
        if not self.user or not self.password:
            logger.warning("smtp_credentials_missing — logging email instead")
            logger.info(
                "[EMAIL/LOG] to=%s subject=%s\n%s",
                message.to,
                message.subject,
                message.text or message.html[:200],
            )
            return EmailResult(success=True, message_id="logged")

        try:
            # Run blocking SMTP in thread pool
            return await asyncio.to_thread(self._send_sync, message)
        except Exception as exc:  # noqa: BLE001
            logger.exception("smtp_send_failed: %s", exc)
            return EmailResult(success=False, error=str(exc))

    def _send_sync(self, message: EmailMessage) -> EmailResult:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = message.subject
        msg["From"] = self.from_addr
        msg["To"] = message.to

        if message.text:
            msg.attach(MIMEText(message.text, "plain"))
        msg.attach(MIMEText(message.html, "html"))

        with smtplib.SMTP(self.host, self.port, timeout=15) as server:
            server.starttls()
            server.login(self.user, self.password)
            server.send_message(msg)

        return EmailResult(success=True, message_id=f"smtp-{message.to}")
