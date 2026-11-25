"""Admin Settings endpoints (Phase 7.2).

⚠️ Ordre critique : les routes spécifiques DOIVENT être déclarées AVANT
les routes génériques `/{key}`, sinon FastAPI matche `/settings/feature-flags`
comme `/settings/{key}` avec key="feature-flags".
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
    MaintenanceOut,
    MaintenanceUpdate,
    SettingsOptionsOut,
)
from app.services.role_service import RoleService
from app.services.settings_service import SettingsService

router = APIRouter()


async def _require_system_manage(session: SessionDep, uid: CurrentUserId) -> None:
    await RoleService(session).require_permission(uid, Permission.SYSTEM_MANAGE)


# ============================================================
# ⚠️ ORDRE : routes spécifiques d'abord, /{key} en DERNIER
# ============================================================


# ---------- 1. Options agrégées ----------


@router.get("/settings/options", response_model=SettingsOptionsOut)
async def get_options(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> SettingsOptionsOut:
    await _require_system_manage(session, current_user_id)
    return await SettingsService(session).get_options()


# ---------- 2. Feature flags ----------


@router.get("/settings/feature-flags", response_model=list[FeatureFlagOut])
async def list_flags(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[FeatureFlagOut]:
    await _require_system_manage(session, current_user_id)
    return await SettingsService(session).list_flags()


@router.patch("/settings/feature-flags/{key}", response_model=FeatureFlagOut)
@router.put("/settings/feature-flags/{key}", response_model=FeatureFlagOut)
async def update_flag(
    key: str,
    payload: FeatureFlagUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> FeatureFlagOut:
    await _require_system_manage(session, current_user_id)
    return await SettingsService(session).update_flag(
        key,
        payload.enabled,
        updated_by=current_user_id,
        admin_email=getattr(admin, "email", None),
        payload=payload,
    )


# ---------- 3. Maintenance ----------


@router.get("/settings/maintenance", response_model=MaintenanceOut)
async def get_maintenance(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> MaintenanceOut:
    await _require_system_manage(session, current_user_id)
    return await SettingsService(session).get_maintenance()


@router.post("/settings/maintenance", response_model=MaintenanceOut)
async def set_maintenance(
    payload: MaintenanceUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> MaintenanceOut:
    await _require_system_manage(session, current_user_id)
    return await SettingsService(session).set_maintenance(
        payload, updated_by=current_user_id
    )


# ---------- 4. Liste settings (générique mais pas /{key}) ----------


@router.get("/settings", response_model=list[AppSettingOut])
async def list_settings(
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> list[AppSettingOut]:
    await _require_system_manage(session, current_user_id)
    return await SettingsService(session).list_settings()


# ---------- 5. Get / Update d'un setting spécifique (EN DERNIER) ----------


@router.get("/settings/{key}", response_model=AppSettingOut)
async def get_setting(
    key: str,
    session: SessionDep,
    current_user_id: CurrentUserId,
    _admin: AdminUser,
) -> AppSettingOut:
    await _require_system_manage(session, current_user_id)
    return await SettingsService(session).get_setting(key)


@router.patch("/settings/{key}", response_model=AppSettingOut)
@router.put("/settings/{key}", response_model=AppSettingOut)
async def update_setting(
    key: str,
    payload: AppSettingUpdate,
    session: SessionDep,
    current_user_id: CurrentUserId,
    admin: AdminUser,
) -> AppSettingOut:
    await _require_system_manage(session, current_user_id)
    return await SettingsService(session).update_setting(
        key,
        payload,
        updated_by=current_user_id,
        admin_email=getattr(admin, "email", None),
    )
