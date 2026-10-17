"""Application configuration loaded from environment variables."""
from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Single source of truth for runtime configuration."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ---------- App ----------
    APP_NAME: str = "MINDORA"
    APP_ENV: Literal["development", "staging", "production", "test"] = "development"
    APP_DEBUG: bool = True
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000
    APP_BASE_URL: str = "http://localhost:8000"
    APP_VERSION: str = "0.1.0"
    APP_TIMEZONE: str = "Africa/Douala"

    # ---------- Security ----------
    JWT_SECRET_KEY: str = Field(default="dev-only-change-me", min_length=8)
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    PASSWORD_HASH_ROUNDS: int = 12
    CORS_ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8080"

    # ---------- Database ----------
    DATABASE_URL: str = (
        "postgresql+asyncpg://mindora:mindora_dev_password@localhost:5432/mindora"
    )
    DATABASE_URL_SYNC: str = (
        "postgresql+psycopg://mindora:mindora_dev_password@localhost:5432/mindora"
    )
    DB_ECHO: bool = False
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20

    # ---------- Redis ----------
    REDIS_URL: str = "redis://localhost:6379/0"

    # ---------- Storage ----------
    S3_ENDPOINT: str = "http://localhost:9000"
    S3_PUBLIC_ENDPOINT: str = "http://localhost:9000"
    S3_REGION: str = "us-east-1"
    S3_ACCESS_KEY: str = "minioadmin"
    S3_SECRET_KEY: str = "minioadmin"
    S3_BUCKET_DOCUMENTS: str = "mindora-documents"
    S3_BUCKET_AVATARS: str = "mindora-avatars"
    S3_BUCKET_TEMP: str = "mindora-temp"
    S3_USE_SSL: bool = False

    # ---------- Vector ----------
    VECTOR_DIM: int = 768

    # ---------- AI ----------
    AI_DEFAULT_PROVIDER: Literal["gemini", "openai", "anthropic"] = "gemini"
    AI_DEFAULT_MODEL: str = "gemini-3.1-flash-lite"
    AI_EMBEDDING_PROVIDER: str = "gemini"
    AI_EMBEDDING_MODEL: str = "gemini-embedding-001"
    AI_REQUEST_TIMEOUT_SECONDS: int = 60
    AI_MAX_RETRIES: int = 2

    OPENAI_API_KEY: str = ""
    OPENAI_BASE_URL: str = "https://api.openai.com/v1"
    ANTHROPIC_API_KEY: str = ""
    ANTHROPIC_BASE_URL: str = "https://api.anthropic.com"
    GEMINI_API_KEY: str = ""
    GEMINI_BASE_URL: str = "https://generativelanguage.googleapis.com"

    # ---------- Search ----------
    SEARCH_PROVIDER: Literal["none", "tavily", "brave", "serpapi"] = "none"
    TAVILY_API_KEY: str = ""
    BRAVE_SEARCH_API_KEY: str = ""
    SERPAPI_API_KEY: str = ""

    # ---------- Notifications ----------
    NOTIFICATION_PROVIDER: Literal["none", "fcm"] = "fcm"
    FCM_PROJECT_ID: str = ""
    FCM_SERVICE_ACCOUNT_PATH: str = ""
    FCM_LEGACY_SERVER_KEY: str = ""

    # ---------- Payments ----------
    PAYMENT_PROVIDER: Literal["none", "flutterwave", "stripe", "campay"] = "flutterwave"
    PAYMENT_REDIRECT_SUCCESS_URL: str = (
        "http://localhost:3000/#/subscription/success"
    )
    PAYMENT_REDIRECT_FAILURE_URL: str = (
        "http://localhost:3000/#/subscription/failure"
    )

    FLUTTERWAVE_SECRET_KEY: str = ""
    FLUTTERWAVE_WEBHOOK_HASH: str = ""
    FLUTTERWAVE_BASE_URL: str = "https://api.flutterwave.com"

    STRIPE_SECRET_KEY: str = ""
    STRIPE_WEBHOOK_SECRET: str = ""

    CAMPAY_APP_TOKEN: str = ""

    # ---------- Rate limiting ----------
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_UPLOAD_PER_HOUR: int = 20

    # ---------- Feature flags ----------
    FEATURE_WEB_RESEARCH: bool = False
    FEATURE_VOICE: bool = False
    FEATURE_VISION: bool = False
    FEATURE_PAYMENTS: bool = True
    FEATURE_CONTRIBUTIONS: bool = True

    # ---------- Observability ----------
    LOG_LEVEL: str = "INFO"

    @computed_field  # type: ignore[misc]
    @property
    def cors_origins(self) -> list[str]:
        # Static extras (Codespaces, local dev)
        extras = [
            "https://*.app.github.dev",  # Codespaces (all subdomains)
            "http://localhost:3000",     # Flutter Web dev
            "http://localhost:8000",     # Backend dev
        ]
        # Dynamic from env
        env_origins = [
            o.strip() for o in self.CORS_ALLOWED_ORIGINS.split(",") if o.strip()
        ]
        return extras + env_origins

    @property
    def is_production(self) -> bool:
        return self.APP_ENV == "production"

    @property
    def is_development(self) -> bool:
        return self.APP_ENV == "development"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return a cached Settings instance."""
    return Settings()


settings = get_settings()
