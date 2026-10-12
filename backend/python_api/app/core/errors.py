"""Application-level exceptions and global exception handlers."""
from __future__ import annotations

from typing import Any

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from app.core.logging import get_logger

logger = get_logger(__name__)


class AppError(Exception):
    """Base application exception. Never leaks internals to clients."""

    code: str = "app_error"
    message: str = "Something went wrong. Please try again."
    status_code: int = status.HTTP_400_BAD_REQUEST

    def __init__(
        self,
        message: str | None = None,
        *,
        code: str | None = None,
        status_code: int | None = None,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(message or self.message)
        if message is not None:
            self.message = message
        if code is not None:
            self.code = code
        if status_code is not None:
            self.status_code = status_code
        self.details = details or {}


class NotFoundError(AppError):
    code = "not_found"
    message = "The requested resource was not found."
    status_code = status.HTTP_404_NOT_FOUND


class ConflictError(AppError):
    code = "conflict"
    message = "A conflicting resource already exists."
    status_code = status.HTTP_409_CONFLICT


class UnauthorizedError(AppError):
    code = "unauthorized"
    message = "Authentication is required."
    status_code = status.HTTP_401_UNAUTHORIZED


class ForbiddenError(AppError):
    code = "forbidden"
    message = "You do not have permission to perform this action."
    status_code = status.HTTP_403_FORBIDDEN


class ValidationError(AppError):
    code = "validation_error"
    message = "The provided data is invalid."
    status_code = status.HTTP_422_UNPROCESSABLE_ENTITY


class RateLimitError(AppError):
    code = "rate_limited"
    message = "Too many requests. Please slow down."
    status_code = status.HTTP_429_TOO_MANY_REQUESTS


def _error_payload(code: str, message: str, details: dict | None = None) -> dict:
    payload: dict[str, Any] = {"error": {"code": code, "message": message}}
    if details:
        payload["error"]["details"] = details
    return payload


def register_exception_handlers(app: FastAPI) -> None:
    """Attach global exception handlers to the FastAPI app."""

    @app.exception_handler(AppError)
    async def _app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_payload(exc.code, exc.message, exc.details),
        )

    @app.exception_handler(RequestValidationError)
    async def _validation_error(_: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=_error_payload(
                "validation_error",
                "The provided data is invalid.",
                {"fields": exc.errors()},
            ),
        )

    @app.exception_handler(IntegrityError)
    async def _integrity_error(_: Request, exc: IntegrityError) -> JSONResponse:
        logger.warning("db_integrity_error", error=str(exc.orig))
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content=_error_payload("conflict", "A conflicting resource already exists."),
        )

    @app.exception_handler(SQLAlchemyError)
    async def _db_error(_: Request, exc: SQLAlchemyError) -> JSONResponse:
        logger.error("db_error", error=str(exc))
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=_error_payload("server_error", "A server error occurred."),
        )

    @app.exception_handler(Exception)
    async def _unhandled(_: Request, exc: Exception) -> JSONResponse:
        logger.exception("unhandled_exception", error=str(exc))
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=_error_payload("server_error", "Something went wrong. Please try again."),
        )
