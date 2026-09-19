"""
Every error the API returns to a client goes through here, so raw
exceptions (stack traces, DB errors, provider errors) never reach the
Flutter app. Backend logs keep the real detail; the client sees only
`safe_message`.
"""
from fastapi import Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    """Base class for all handled application errors."""

    code: str = "internal_error"
    safe_message: str = "Something went wrong. Please try again."
    status_code: int = 500

    def __init__(self, safe_message: str | None = None, *, detail: str | None = None):
        self.safe_message = safe_message or self.safe_message
        self.detail = detail  # logged, never returned to the client
        super().__init__(self.detail or self.safe_message)


class NotFoundError(AppError):
    code = "not_found"
    safe_message = "We couldn't find what you're looking for."
    status_code = 404


class ValidationFailedError(AppError):
    code = "validation_failed"
    safe_message = "Please check your input and try again."
    status_code = 422


class UnauthorizedError(AppError):
    code = "unauthorized"
    safe_message = "Please sign in again to continue."
    status_code = 401


class ForbiddenError(AppError):
    code = "forbidden"
    safe_message = "You don't have permission to do this."
    status_code = 403


class DocumentProcessingError(AppError):
    code = "document_processing_failed"
    safe_message = "We couldn't process this document. Please try uploading it again."
    status_code = 422


def envelope(data=None, error: AppError | None = None) -> dict:
    if error is None:
        return {"data": data, "error": None}
    return {"data": None, "error": {"code": error.code, "message": error.safe_message}}


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code, content=envelope(error=exc))


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    # Never leak internals — this is the last line of defense.
    generic = AppError()
    return JSONResponse(status_code=500, content=envelope(error=generic))
