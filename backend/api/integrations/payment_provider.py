"""
Payment provider interface (Replaceability Matrix), section 69: real
payment processing needs a merchant account and region-specific
integration (mobile money in Cameroon, cards elsewhere) that this
environment can't test with a live charge. Same pattern as every other
external service here: a deterministic `MockPaymentProvider` for dev/
test, and the real adapter's shape documented for when a provider is
actually configured — get_payment_provider() must not silently keep
returning the mock in a real deployment once money is meant to move.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class ChargeResult:
    success: bool
    provider_reference: str | None
    error_message: str | None = None


class PaymentProvider(ABC):
    @abstractmethod
    async def charge(
        self, user_id: str, amount_minor_units: int, currency: str, description: str
    ) -> ChargeResult:
        ...


class MockPaymentProvider(PaymentProvider):
    """Always succeeds — dev/test stand-in only. Never returns failure,
    so it must never be mistaken for a real payment integration."""

    async def charge(
        self, user_id: str, amount_minor_units: int, currency: str, description: str
    ) -> ChargeResult:
        import uuid

        return ChargeResult(success=True, provider_reference=f"mock_{uuid.uuid4().hex[:12]}")


def get_payment_provider() -> PaymentProvider:
    # Later: branch on settings.payment_provider ("mobile_money", "stripe",
    # ...) to return a real adapter for the target market (section 69).
    return MockPaymentProvider()
