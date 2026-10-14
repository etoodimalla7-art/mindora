"""Payment provider factory — the only place that knows about concrete providers."""
from __future__ import annotations

from functools import lru_cache

from app.core.config import settings
from app.core.errors import AppError
from app.integrations.payments.flutterwave import FlutterwaveProvider
from app.integrations.payments.provider import PaymentProvider


@lru_cache(maxsize=4)
def get_payment_provider(name: str | None = None) -> PaymentProvider:
    provider_name = (name or settings.PAYMENT_PROVIDER).lower()
    if provider_name == "flutterwave":
        return FlutterwaveProvider()
    if provider_name == "none":
        raise AppError(
            "Payments are not enabled on this server.",
            code="payments_disabled",
            status_code=503,
        )
    raise AppError(
        f"Unknown payment provider: {provider_name}",
        code="payment_provider_unknown",
        status_code=500,
    )
