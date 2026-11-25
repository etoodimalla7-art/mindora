"""Payment provider interface — implemented by Flutterwave, Stripe, Campay, etc."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol


@dataclass(slots=True)
class CheckoutRequest:
    """Input to create a checkout session."""

    reference: str          # our unique id
    amount_minor: int       # amount in smallest currency unit
    currency: str           # XAF, USD, EUR, ...
    customer_email: str
    customer_name: str
    redirect_url: str       # where to send the user after checkout
    description: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class CheckoutResponse:
    """What the client needs to complete the payment."""

    provider: str
    provider_reference: str
    checkout_url: str       # link the client opens
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class WebhookEvent:
    """Normalized webhook event from any provider."""

    provider: str
    reference: str          # our reference (or provider's, when we resolve it)
    provider_reference: str | None
    status: str             # "succeeded" | "failed" | "refunded" | "pending"
    amount_minor: int | None
    currency: str | None
    raw: dict[str, Any] = field(default_factory=dict)


class PaymentProvider(Protocol):
    name: str

    async def create_checkout(self, req: CheckoutRequest) -> CheckoutResponse: ...

    async def verify_payment(self, reference: str) -> WebhookEvent:
        """Actively ask the provider the status of a payment."""
        ...

    def verify_webhook_signature(self, headers: dict[str, str], body: bytes) -> bool:
        """Return True if the webhook is authentic."""
        ...

    def parse_webhook(self, body: bytes) -> WebhookEvent:
        """Parse a raw webhook body into our normalized event."""
        ...
