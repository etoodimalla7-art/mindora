"""Flutterwave payment provider.

Docs: https://developer.flutterwave.com/docs/standard

This module is a thin REST wrapper. It supports both sandbox and live modes
via the FLUTTERWAVE_BASE_URL env var.
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging
from typing import Any

import httpx

from app.core.config import settings
from app.core.errors import AppError
from app.integrations.payments.provider import (
    CheckoutRequest,
    CheckoutResponse,
    WebhookEvent,
)

logger = logging.getLogger(__name__)


class FlutterwaveProvider:
    name = "flutterwave"

    def __init__(
        self,
        secret_key: str | None = None,
        webhook_hash: str | None = None,
        base_url: str | None = None,
    ) -> None:
        self._secret = secret_key or settings.FLUTTERWAVE_SECRET_KEY
        self._hash = webhook_hash or settings.FLUTTERWAVE_WEBHOOK_HASH
        self._base = (
            base_url or settings.FLUTTERWAVE_BASE_URL
        ).rstrip("/")

    def _require_secret(self) -> str:
        if not self._secret:
            raise AppError(
                "Payment provider is not configured.",
                code="payment_unconfigured",
                status_code=503,
            )
        return self._secret

    # ---------- Checkout ----------

    async def create_checkout(self, req: CheckoutRequest) -> CheckoutResponse:
        """Create a Flutterwave Standard checkout session."""
        secret = self._require_secret()

        payload: dict[str, Any] = {
            "tx_ref": req.reference,
            "amount": self._to_float(req.amount_minor, req.currency),
            "currency": req.currency,
            "redirect_url": req.redirect_url,
            "customer": {
                "email": req.customer_email,
                "name": req.customer_name,
            },
            "customizations": {
                "title": "MINDORA",
                "description": req.description or "MINDORA subscription",
            },
            "meta": req.metadata or {},
        }

        headers = {
            "Authorization": f"Bearer {secret}",
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.post(
                f"{self._base}/v3/payments",
                json=payload,
                headers=headers,
            )

        if r.status_code >= 400:
            logger.error(
                "flutterwave_checkout_failed status=%s body=%s",
                r.status_code,
                r.text[:300],
            )
            raise AppError(
                "Payment could not be initiated. Please try again.",
                code="payment_init_failed",
                status_code=502,
            )

        data = r.json().get("data") or {}
        link = data.get("link")
        if not link:
            raise AppError(
                "Payment provider returned an unexpected response.",
                code="payment_bad_response",
                status_code=502,
            )

        return CheckoutResponse(
            provider=self.name,
            provider_reference=str(data.get("id") or req.reference),
            checkout_url=link,
            raw=data,
        )

    # ---------- Verify ----------

    async def verify_payment(self, reference: str) -> WebhookEvent:
        """Query Flutterwave for the current status of a payment by tx_ref."""
        secret = self._require_secret()
        headers = {"Authorization": f"Bearer {secret}"}

        async with httpx.AsyncClient(timeout=20) as client:
            r = await client.get(
                f"{self._base}/v3/transactions/verify_by_reference",
                params={"tx_ref": reference},
                headers=headers,
            )

        if r.status_code >= 400:
            logger.warning(
                "flutterwave_verify_failed status=%s body=%s",
                r.status_code,
                r.text[:200],
            )
            return WebhookEvent(
                provider=self.name,
                reference=reference,
                provider_reference=None,
                status="pending",
                amount_minor=None,
                currency=None,
                raw={},
            )

        data = r.json().get("data") or {}
        return self._to_event(data)

    # ---------- Webhook ----------

    def verify_webhook_signature(
        self, headers: dict[str, str], body: bytes
    ) -> bool:
        """Flutterwave sends the webhook secret in the `verif-hash` header."""
        if not self._hash:
            # Not configured; accept in dev but warn.
            logger.warning("flutterwave_webhook_hash_missing — skipping verification")
            return True
        incoming = (
            headers.get("verif-hash")
            or headers.get("Verif-Hash")
            or headers.get("VERIF-HASH")
        )
        if not incoming:
            return False
        return hmac.compare_digest(incoming, self._hash)

    def parse_webhook(self, body: bytes) -> WebhookEvent:
        try:
            payload = json.loads(body.decode("utf-8"))
        except Exception as exc:  # noqa: BLE001
            logger.error("flutterwave_webhook_parse_failed error=%s", exc)
            raise AppError(
                "Invalid webhook payload.",
                code="webhook_bad_payload",
                status_code=400,
            ) from exc

        data = payload.get("data") or {}
        # Flutterwave includes our tx_ref in `data.tx_ref`.
        reference = data.get("tx_ref") or data.get("reference") or ""

        return self._to_event(data, fallback_reference=reference)

    # ---------- Helpers ----------

    @staticmethod
    def _to_float(amount_minor: int, currency: str) -> float:
        # XAF/EUR/USD all have 2 decimals in Flutterwave's API (XAF is integer in reality,
        # but Flutterwave expects a float). We store minor units internally for safety.
        return round(amount_minor / 100.0, 2)

    def _to_event(
        self, data: dict[str, Any], fallback_reference: str | None = None
    ) -> WebhookEvent:
        status_raw = str(data.get("status", "")).lower()
        status = {
            "successful": "succeeded",
            "success": "succeeded",
            "completed": "succeeded",
            "failed": "failed",
            "cancelled": "failed",
            "refunded": "refunded",
        }.get(status_raw, "pending")

        amount = data.get("amount")
        currency = data.get("currency")

        return WebhookEvent(
            provider=self.name,
            reference=str(data.get("tx_ref") or fallback_reference or ""),
            provider_reference=str(data.get("id") or "") or None,
            status=status,
            amount_minor=int(round(float(amount) * 100)) if amount else None,
            currency=str(currency) if currency else None,
            raw=data,
        )


# --- Simple helper to compute a local HMAC signature for debugging ---
def _sign_debug(secret: str, body: bytes) -> str:
    return hashlib.sha256(secret.encode() + body).hexdigest()
