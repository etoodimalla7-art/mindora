"""Firebase Cloud Messaging (FCM) provider.

Uses the HTTP v1 API with a Service Account JSON for authentication.
Falls back to a no-op (log only) if not configured.
"""
from __future__ import annotations

import json
import logging
import time
from pathlib import Path
from typing import Any

import httpx
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2 import service_account

from app.core.config import settings
from app.integrations.notifications.provider import (
    NotificationProvider,
    PushMessage,
    PushResult,
)

logger = logging.getLogger(__name__)

# OAuth scope for FCM
_FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
# Cache access token for ~55 min (tokens expire in 60 min)
_TOKEN_TTL_SECONDS = 55 * 60


class FCMProvider:
    name = "fcm"

    def __init__(
        self,
        service_account_path: str | None = None,
        project_id: str | None = None,
    ) -> None:
        self._sa_path = service_account_path or settings.FCM_SERVICE_ACCOUNT_PATH
        self._project_id = project_id or settings.FCM_PROJECT_ID
        self._credentials: service_account.Credentials | None = None
        self._access_token: str | None = None
        self._access_token_expires_at: float = 0.0

    def is_configured(self) -> bool:
        if not self._sa_path or not self._project_id:
            return False
        return Path(self._sa_path).exists()

    def _get_credentials(self) -> service_account.Credentials | None:
        if self._credentials is not None:
            return self._credentials
        if not self.is_configured():
            return None
        try:
            self._credentials = service_account.Credentials.from_service_account_file(
                self._sa_path, scopes=[_FCM_SCOPE]
            )
            return self._credentials
        except Exception as exc:  # noqa: BLE001
            logger.error("fcm_credentials_failed error=%s", exc)
            return None

    def _get_access_token(self) -> str | None:
        now = time.time()
        if self._access_token and now < self._access_token_expires_at:
            return self._access_token

        creds = self._get_credentials()
        if creds is None:
            return None

        try:
            creds.refresh(GoogleAuthRequest())
            self._access_token = creds.token
            self._access_token_expires_at = now + _TOKEN_TTL_SECONDS
            return self._access_token
        except Exception as exc:  # noqa: BLE001
            logger.error("fcm_token_refresh_failed error=%s", exc)
            return None

    async def send(self, message: PushMessage) -> PushResult:
        if not self.is_configured():
            logger.info(
                "fcm_not_configured — would send: title=%s token=%s...",
                message.title,
                message.token[:20],
            )
            return PushResult(
                success=True,
                message_id="mock-" + message.token[:8],
                error=None,
                raw={"mock": True},
            )

        access_token = self._get_access_token()
        if access_token is None:
            return PushResult(success=False, error="Could not obtain FCM access token")

        payload: dict[str, Any] = {
            "message": {
                "token": message.token,
                "notification": {
                    "title": message.title,
                    "body": message.body,
                },
                "android": {
                    "priority": message.priority,
                    "notification": {
                        "sound": "default",
                        "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    },
                },
                "data": {
                    **(message.data or {}),
                    "deep_link": message.deep_link or "",
                },
            }
        }
        if message.image_url:
            payload["message"]["notification"]["image"] = message.image_url

        url = (
            f"https://fcm.googleapis.com/v1/projects/{self._project_id}/messages:send"
        )

        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.post(
                url,
                json=payload,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
            )

        if r.status_code >= 400:
            logger.error("fcm_send_failed status=%s body=%s", r.status_code, r.text[:300])
            return PushResult(
                success=False,
                error=f"FCM error {r.status_code}: {r.text[:200]}",
                raw={"status": r.status_code, "body": r.text[:500]},
            )

        data = r.json()
        return PushResult(
            success=True,
            message_id=data.get("name"),
            raw=data,
        )

    async def send_batch(self, messages: list[PushMessage]) -> list[PushResult]:
        results: list[PushResult] = []
        for m in messages:
            results.append(await self.send(m))
        return results


# Log helper for debugging
def _log_payload(payload: dict) -> None:
    logger.debug("fcm_payload=%s", json.dumps(payload)[:500])
