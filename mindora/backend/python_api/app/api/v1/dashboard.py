"""Home dashboard endpoint."""
from __future__ import annotations

from fastapi import APIRouter

from app.api.deps import CurrentUserId, SessionDep
from app.schemas.dashboard import DashboardResponse
from app.services.dashboard_service import DashboardService

router = APIRouter()


@router.get("", response_model=DashboardResponse)
async def get_dashboard(session: SessionDep, user_id: CurrentUserId) -> DashboardResponse:
    return await DashboardService(session).build(user_id)
