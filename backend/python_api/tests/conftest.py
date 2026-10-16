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
from uuid import uuid4

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
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
from app.models.notification import Device  # noqa: E402
from app.models.user import User  # noqa: E402


# ----------------------------------------------------------------------
# Fixtures — app & HTTP client
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
# Fixtures — DB session & user/device builders (global)
# ----------------------------------------------------------------------
@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Real async DB session, rolled back at the end.

    Note: we commit inside tests, so rollback is best-effort; explicit
    cleanup is the responsibility of each test (or use `test_user`).
    """
    async with _session_module.AsyncSessionLocal() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession) -> AsyncGenerator[User, None]:
    """Create a throwaway user; delete it (cascades) after the test."""
    email = f"test-{uuid4().hex[:8]}@mindora.dev"
    user = User(
        email=email,
        hashed_password="not-used",
        full_name="Test User",
        is_admin=False,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    yield user

    try:
        await db_session.execute(delete(User).where(User.id == user.id))
        await db_session.commit()
    except Exception:
        await db_session.rollback()


@pytest_asyncio.fixture
async def test_device(
    db_session: AsyncSession, test_user: User
) -> Device:
    """Create a device attached to `test_user`."""
    device = Device(
        user_id=test_user.id,
        fcm_token=f"token-{uuid4().hex[:16]}",
        platform="android",
        notifications_enabled=True,
    )
    db_session.add(device)
    await db_session.commit()
    await db_session.refresh(device)
    return device


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
