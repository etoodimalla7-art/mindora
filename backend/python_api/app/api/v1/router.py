"""Aggregate router for /api/v1."""
from __future__ import annotations

from fastapi import APIRouter

from app.api.v1 import (
    admin,
    ai,
    auth,
    credits,
    dashboard,
    documents,
    health,
    planner,
    users,
)

api_router = APIRouter()
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(planner.router, prefix="/planner", tags=["planner"])
api_router.include_router(documents.router, prefix="/documents", tags=["documents"])
api_router.include_router(credits.router, prefix="/credits", tags=["credits"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(ai.router, prefix="/ai", tags=["ai"])
