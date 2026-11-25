"""Public settings endpoints — NO AUTH required.

Used by mobile app to check maintenance status at boot.
"""
from __future__ import annotations

from fastapi import APIRouter

from app.api.deps import AdminUser, CurrentUserId, SessionDep
from app.core.permissions import Permission
from app.schemas.settings import (
    AppSettingOut,
    AppSettingUpdate,
    FeatureFlagOut,
    FeatureFlagUpdate,
    MaintenancePublicOut,
    PublicSettingsOut,
)
from app.services.role_service import RoleService
from app.services.settings_service import SettingsService

router = APIRouter()


@router.get("/settings/maintenance", response_model=MaintenancePublicOut)
async def public_maintenance(session: SessionDep) -> MaintenancePublicOut:
    """Public maintenance info — accessible sans token."""
    m = await SettingsService(session).get_maintenance()
    return MaintenancePublicOut(
        enabled=m.enabled,
        message=m.message,
        eta=m.eta,
    )


@router.get("/settings/public", response_model=PublicSettingsOut)
async def public_settings(session: SessionDep) -> PublicSettingsOut:
    """Public aggregated config (identity, languages, systems, flags, settings, CMS)."""
    payload = await SettingsService(session).get_public_config()
    return PublicSettingsOut(**payload)


@router.get("/settings/admin", response_model=list[AppSettingOut])
async def admin_list_settings_alias(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[AppSettingOut]:
    await RoleService(session).require_permission(
        current_user_id, Permission.SYSTEM_MANAGE
    )
    return await SettingsService(session).list_settings()


@router.put("/settings/admin/{key}", response_model=AppSettingOut)
async def admin_update_setting_alias(
    key: str,
    payload: AppSettingUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> AppSettingOut:
    await RoleService(session).require_permission(
        current_user_id, Permission.SYSTEM_MANAGE
    )
    return await SettingsService(session).update_setting(
        key,
        payload,
        updated_by=current_user_id,
        admin_email=getattr(admin, "email", None),
    )


@router.get("/feature-flags", response_model=list[FeatureFlagOut])
async def public_feature_flags(session: SessionDep) -> list[FeatureFlagOut]:
    """List product feature flags."""
    return await SettingsService(session).list_flags()


@router.put("/feature-flags/{key}", response_model=FeatureFlagOut)
async def admin_update_feature_flag(
    key: str,
    payload: FeatureFlagUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> FeatureFlagOut:
    await RoleService(session).require_permission(
        current_user_id, Permission.SYSTEM_MANAGE
    )
    return await SettingsService(session).update_flag(
        key,
        payload.enabled,
        updated_by=current_user_id,
        admin_email=getattr(admin, "email", None),
        payload=payload,
    )
