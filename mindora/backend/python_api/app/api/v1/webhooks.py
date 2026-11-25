"""Webhook receiver for payment providers."""
from __future__ import annotations

import logging

from fastapi import APIRouter, Request, Response, status

from app.api.deps import SessionDep
from app.integrations.payments.factory import get_payment_provider
from app.services.subscription_service import SubscriptionService

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/flutterwave", status_code=status.HTTP_200_OK)
async def flutterwave_webhook(
    request: Request,
    session: SessionDep,
) -> Response:
    """Receive Flutterwave webhook events.

    Flutterwave expects a 200 OK quickly, even if processing fails.
    """
    body = await request.body()
    headers = {k.lower(): v for k, v in request.headers.items()}

    provider = get_payment_provider("flutterwave")

    if not provider.verify_webhook_signature(headers, body):
        logger.warning("webhook_signature_invalid")
        return Response(status_code=status.HTTP_401_UNAUTHORIZED)

    try:
        event = provider.parse_webhook(body)
    except Exception as exc:  # noqa: BLE001
        logger.error("webhook_parse_failed error=%s", exc)
        return Response(status_code=status.HTTP_400_BAD_REQUEST)

    try:
        await SubscriptionService(session).handle_webhook_event(event)
    except Exception as exc:  # noqa: BLE001
        logger.exception("webhook_processing_failed error=%s", exc)
        # Still return 200 so the provider does not retry endlessly.

    return Response(status_code=status.HTTP_200_OK)
