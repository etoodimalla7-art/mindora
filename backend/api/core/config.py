"""
Centralized configuration. Nothing here is hardcoded — every value is
read from the environment so secrets never live in source control and the
same code runs in dev/staging/prod.
"""
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # App
    app_name: str = "MINDORA"
    api_v1_prefix: str = "/api/v1"
    environment: str = "development"
    debug: bool = True

    # Security
    secret_key: str
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30
    algorithm: str = "HS256"

    # Database
    database_url: str

    # Object storage
    storage_provider: str = "s3"
    storage_bucket: str = "mindora-documents"
    storage_endpoint: str | None = None
    storage_access_key: str | None = None
    storage_secret_key: str | None = None

    # AI providers (swappable — see api/integrations)
    llm_provider: str = "anthropic"
    llm_api_key: str | None = None
    web_search_provider: str | None = None
    web_search_api_key: str | None = None

    # Payments (configured later — see section 69 of product spec)
    payment_provider: str | None = None
    default_currency: str = "XAF"
    # Placeholder prices in minor currency units (e.g. centimes) — the
    # spec explicitly defers the final amount ("will be configured
    # later"). Reading from settings, not hardcoded in business logic,
    # means changing the price never requires a code change.
    subscription_monthly_price_minor_units: int = 0
    subscription_yearly_price_minor_units: int = 0

    # CORS
    allowed_origins: list[str] = ["*"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
