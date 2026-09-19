from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded

from api.core.config import get_settings
from api.core.errors import AppError, app_error_handler, unhandled_exception_handler
from api.core.rate_limit import limiter
from api.core.security_headers import SecurityHeadersMiddleware
from api.core.startup_checks import check_production_safety
from api.modules.auth.router import router as auth_router
from api.modules.users.router import router as users_router
from api.modules.study_sessions.router import router as study_sessions_router
from api.modules.progress.router import router as progress_router
from api.modules.catalog.router import router as catalog_router
from api.modules.documents.router import router as documents_router
from api.modules.past_papers.router import router as past_papers_router
from api.modules.planner.router import router as planner_router
from api.modules.ai_chat.router import router as ai_chat_router
from api.modules.flashcards.router import router as flashcards_router
from api.modules.quizzes.router import router as quizzes_router
from api.modules.mock_exams.router import router as mock_exams_router
from api.modules.notifications.router import router as notifications_router
from api.modules.credits.router import router as credits_router
from api.modules.subscriptions.router import router as subscriptions_router
from api.modules.admin.router import router as admin_router

settings = get_settings()


async def rate_limit_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    return JSONResponse(
        status_code=429,
        content={"data": None, "error": {
            "code": "rate_limited",
            "message": "Too many requests. Please wait a moment and try again.",
        }},
    )


def create_app() -> FastAPI:
    check_production_safety(settings)

    app = FastAPI(title=settings.app_name, debug=settings.debug)

    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, rate_limit_handler)

    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.add_exception_handler(AppError, app_error_handler)
    app.add_exception_handler(Exception, unhandled_exception_handler)

    prefix = settings.api_v1_prefix
    app.include_router(auth_router, prefix=prefix)
    app.include_router(users_router, prefix=prefix)
    app.include_router(study_sessions_router, prefix=prefix)
    app.include_router(progress_router, prefix=prefix)
    app.include_router(catalog_router, prefix=prefix)
    app.include_router(documents_router, prefix=prefix)
    app.include_router(past_papers_router, prefix=prefix)
    app.include_router(planner_router, prefix=prefix)
    app.include_router(ai_chat_router, prefix=prefix)
    app.include_router(flashcards_router, prefix=prefix)
    app.include_router(quizzes_router, prefix=prefix)
    app.include_router(mock_exams_router, prefix=prefix)
    app.include_router(notifications_router, prefix=prefix)
    app.include_router(credits_router, prefix=prefix)
    app.include_router(subscriptions_router, prefix=prefix)
    app.include_router(admin_router, prefix=prefix)

    @app.get("/health")
    async def health():
        return {"status": "ok", "app": settings.app_name}

    return app


app = create_app()
