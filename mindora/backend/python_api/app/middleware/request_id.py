"""Middleware that assigns a request ID and binds it to log context."""
from __future__ import annotations

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from structlog.contextvars import bind_contextvars, clear_contextvars

from app.core.ids import new_request_id

REQUEST_ID_HEADER = "X-Request-ID"


class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        clear_contextvars()
        incoming = request.headers.get(REQUEST_ID_HEADER)
        request_id = incoming or new_request_id()
        bind_contextvars(request_id=request_id, path=request.url.path, method=request.method)

        response = await call_next(request)
        response.headers[REQUEST_ID_HEADER] = request_id
        return response
