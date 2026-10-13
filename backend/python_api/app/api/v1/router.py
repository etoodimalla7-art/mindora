"""Aggregate router for /api/v1."""
from __future__ import annotations

from fastapi import APIRouter

from app.api.v1 import auth, dashboard, documents, health, planner, users

api_router = APIRouter()
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(planner.router, prefix="/planner", tags=["planner"])
api_router.include_router(documents.router, prefix="/documents", tags=["documents"])
