"""
Section 29/69: the subscription plan catalog. Prices are explicit
placeholders (see api/core/config.py) — never hardcode a real price
into this function; when the business finalizes pricing, it changes in
one place (settings/.env), not in code.
"""
from api.core.config import get_settings


def get_plans() -> list[dict]:
    settings = get_settings()
    return [
        {
            "code": "monthly",
            "name": "MINDORA Premium (Monthly)",
            "amount_minor_units": settings.subscription_monthly_price_minor_units,
            "currency": settings.default_currency,
            "interval": "month",
        },
        {
            "code": "yearly",
            "name": "MINDORA Premium (Yearly)",
            "amount_minor_units": settings.subscription_yearly_price_minor_units,
            "currency": settings.default_currency,
            "interval": "year",
        },
    ]
