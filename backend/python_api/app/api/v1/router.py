"""Aggregate router for /api/v1."""
from __future__ import annotations

from fastapi import APIRouter

from app.api.v1 import (
    admin,
    papers,
    flashcards,
    ai,
    auth,
    credits,
    dashboard,
    documents,
    health,
    mock_exams,
    notifications,
    planner,
    study_groups,
    study_groups_ws,
    subscriptions,
    users,
    webhooks,
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
api_router.include_router(papers.router, prefix="/papers", tags=["papers"])
api_router.include_router(flashcards.router, prefix="/flashcards", tags=["flashcards"])
api_router.include_router(ai.router, prefix="/ai", tags=["ai"])
api_router.include_router(
    mock_exams.router, prefix="/mock-exams", tags=["mock-exams"]
)
api_router.include_router(
    subscriptions.router, prefix="/subscriptions", tags=["subscriptions"]
)
api_router.include_router(
    notifications.router, prefix="/notifications", tags=["notifications"]
)
api_router.include_router(webhooks.router, prefix="/webhooks", tags=["webhooks"])

# Phase 13 — study groups
api_router.include_router(
    study_groups.router, prefix="/study-groups", tags=["study-groups"]
)

# Phase 13.4 — WebSocket real-time chat
api_router.include_router(
    study_groups_ws.router, prefix="/study-groups", tags=["study-groups-ws"]
)
