"""Shared pytest fixtures.

Note on asyncpg/SQLAlchemy warnings:
    SQLAlchemy keeps pooled asyncpg connections alive. When pytest closes
    the event loop at the end of the session, the GC tries to clean them
    up against a dead loop and prints "Event loop is closed" warnings.

    We avoid this by disabling the connection pool for tests via
    ``NullPool`` — every request opens and closes its own connection, so
    nothing is left over when the loop dies.
"""
from __future__ import annotations

from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.pool import NullPool

# IMPORTANT: patch the engine BEFORE importing app.main (which imports
# the session module and instantiates the engine with the default pool).
from sqlalchemy.ext.asyncio import create_async_engine

from app.core.config import settings  # noqa: E402

_original_engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    poolclass=NullPool,  # <-- disables pooling
    future=True,
)

import app.db.session as _session_module  # noqa: E402

_session_module.engine = _original_engine
_session_module.AsyncSessionLocal.configure(bind=_original_engine)

from app.main import create_app  # noqa: E402


@pytest.fixture(scope="session")
def app():
    return create_app()


@pytest_asyncio.fixture
async def client(app) -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
