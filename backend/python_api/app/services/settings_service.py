"""Settings service (Phase 7.2)."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.models.app_settings import AppSetting, FeatureFlag
from app.schemas.settings import (
    AppSettingOut,
    AppSettingUpdate,
    FeatureFlagOut,
    MaintenanceOut,
    MaintenanceUpdate,
    SettingsOptionsOut,
)

logger = logging.getLogger(__name__)


class SettingsService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- App Settings ----------

    async def list_settings(self) -> list[AppSettingOut]:
        rows = (
            await self.session.execute(
                select(AppSetting).order_by(AppSetting.key)
            )
        ).scalars().all()
        return [AppSettingOut.model_validate(r) for r in rows]

    async def get_setting(self, key: str) -> AppSettingOut:
        row = (
            await self.session.execute(
                select(AppSetting).where(AppSetting.key == key)
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError(f"Setting '{key}' introuvable.")
        return AppSettingOut.model_validate(row)

    async def update_setting(
        self,
        key: str,
        payload: AppSettingUpdate,
        updated_by: uuid.UUID | None = None,
    ) -> AppSettingOut:
        row = (
            await self.session.execute(
                select(AppSetting).where(AppSetting.key == key)
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError(f"Setting '{key}' introuvable.")

        row.value = payload.value
        row.updated_by = updated_by
        row.updated_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(row)
        return AppSettingOut.model_validate(row)

    # ---------- Feature Flags ----------

    async def list_flags(self) -> list[FeatureFlagOut]:
        rows = (
            await self.session.execute(
                select(FeatureFlag).order_by(FeatureFlag.key)
            )
        ).scalars().all()
        return [FeatureFlagOut.model_validate(r) for r in rows]

    async def update_flag(
        self,
        key: str,
        enabled: bool,
        updated_by: uuid.UUID | None = None,
    ) -> FeatureFlagOut:
        row = (
            await self.session.execute(
                select(FeatureFlag).where(FeatureFlag.key == key)
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError(f"Feature flag '{key}' introuvable.")

        row.enabled = enabled
        row.updated_by = updated_by
        row.updated_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(row)
        return FeatureFlagOut.model_validate(row)

    # ---------- Maintenance ----------

    async def get_maintenance(self) -> MaintenanceOut:
        row = (
            await self.session.execute(
                select(AppSetting).where(AppSetting.key == "maintenance")
            )
        ).scalar_one_or_none()
        if not row:
            # fallback defaults
            return MaintenanceOut(enabled=False, message="", eta=None)

        v = row.value or {}
        return MaintenanceOut(
            enabled=bool(v.get("enabled", False)),
            message=str(v.get("message", "") or ""),
            eta=(
                datetime.fromisoformat(v["eta"])
                if isinstance(v.get("eta"), str)
                else v.get("eta")
            ),
        )

    async def set_maintenance(
        self,
        payload: MaintenanceUpdate,
        updated_by: uuid.UUID | None = None,
    ) -> MaintenanceOut:
        row = (
            await self.session.execute(
                select(AppSetting).where(AppSetting.key == "maintenance")
            )
        ).scalar_one_or_none()
        if not row:
            raise NotFoundError("Setting 'maintenance' introuvable.")

        value = {
            "enabled": payload.enabled,
            "message": payload.message,
            "eta": payload.eta.isoformat() if payload.eta else None,
        }
        row.value = value
        row.updated_by = updated_by
        row.updated_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(row)

        return MaintenanceOut(
            enabled=payload.enabled,
            message=payload.message,
            eta=payload.eta,
        )

    # ---------- Aggregated ----------

    async def get_options(self) -> SettingsOptionsOut:
        """Returns all settings + flags in a single payload for the frontend."""
        rows = (
            await self.session.execute(select(AppSetting))
        ).scalars().all()
        by_key = {r.key: r.value for r in rows}

        # identity
        identity = {
            "name": by_key.get("app.name", "MINDORA"),
            "tagline": by_key.get("app.tagline", {"fr": "", "en": ""}),
            "logo_url": by_key.get("app.logo_url", ""),
            "primary_color": by_key.get("app.primary_color", "#6E8DFF"),
        }

        # languages
        languages = {
            "default": by_key.get("app.default_language", "fr"),
            "active": by_key.get("app.active_languages", ["fr", "en"]),
        }

        # maintenance
        m = by_key.get("maintenance") or {}
        maintenance = MaintenanceOut(
            enabled=bool(m.get("enabled", False)),
            message=str(m.get("message", "") or ""),
            eta=(
                datetime.fromisoformat(m["eta"])
                if isinstance(m.get("eta"), str)
                else m.get("eta")
            ),
        )

        # flags
        flags = await self.list_flags()

        return SettingsOptionsOut(
            identity=identity,
            languages=languages,
            education_systems=by_key.get("education_systems", []),
            subjects=by_key.get("subjects", []),
            levels=by_key.get("levels", []),
            years=by_key.get("years", []),
            maintenance=maintenance,
            feature_flags=flags,
        )
