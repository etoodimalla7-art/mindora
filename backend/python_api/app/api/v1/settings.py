"""Public settings endpoints — NO AUTH required.

Used by mobile app to check maintenance status at boot.
"""
from __future__ import annotations

from fastapi import APIRouter

from app.api.deps import SessionDep
from app.schemas.settings import MaintenancePublicOut
from app.services.settings_service import SettingsService

router = APIRouter()


@router.get("/settings/maintenance", response_model=MaintenancePublicOut)
async def public_maintenance(session: SessionDep) -> MaintenancePublicOut:
    """Public maintenance info — accessible sans token.

    Le mobile appelle cet endpoint au démarrage.
    Si enabled=true → écran de maintenance.
    """
    m = await SettingsService(session).get_maintenance()
    return MaintenancePublicOut(
        enabled=m.enabled,
        message=m.message,
        eta=m.eta,
    )
