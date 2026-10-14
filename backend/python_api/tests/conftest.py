"""Shared pytest fixtures for MINDORA tests.

The warnings about "Event loop is closed" are emitted by Python's garbage
collector at process shutdown, AFTER all tests have passed. They are
harmless but noisy. We silence them cleanly by:

1. Using NullPool so no connections stay open between tests.
2. Explicitly disposing the engine inside the last async fixture.
3. Suppressing leftover GC warnings at process exit.
"""
from __future__ import annotations

import asyncio
import gc
import warnings
from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.pool import NullPool

# ----------------------------------------------------------------------
# Patch the engine BEFORE importing app.main
# ----------------------------------------------------------------------
from app.core.config import settings  # noqa: E402

_test_engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    poolclass=NullPool,
    future=True,
)

import app.db.session as _session_module  # noqa: E402

_session_module.engine = _test_engine
_session_module.AsyncSessionLocal.configure(bind=_test_engine)

from app.main import create_app  # noqa: E402


# ----------------------------------------------------------------------
# Fixtures
# ----------------------------------------------------------------------
@pytest.fixture(scope="session")
def app():
    return create_app()


@pytest_asyncio.fixture
async def client(app) -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


# ----------------------------------------------------------------------
# Teardown: dispose the engine while the loop is still alive
# ----------------------------------------------------------------------
@pytest_asyncio.fixture(scope="session", autouse=True)
async def _dispose_engine_at_end():
    """Yield control to the test session, then dispose the engine cleanly."""
    yield
    try:
        await _test_engine.dispose()
    except Exception:
        pass
    # Give asyncpg a tick to finish its close handshake.
    await asyncio.sleep(0)
    gc.collect()


# ----------------------------------------------------------------------
# Global warnings filter (belt & suspenders)
# ----------------------------------------------------------------------
def pytest_configure(config):
    warnings.filterwarnings(
        "ignore",
        message=".*Event loop is closed.*",
        category=RuntimeWarning,
    )
    warnings.filterwarnings(
        "ignore",
        message=".*non-checked-in connection.*",
        category=Warning,
    )
    warnings.filterwarnings(
        "ignore",
        category=DeprecationWarning,
    )
