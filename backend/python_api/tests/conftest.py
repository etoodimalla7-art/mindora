"""Shared pytest fixtures."""
from __future__ import annotations

from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app.main import create_app


@pytest.fixture(scope="session")
def app():
    return create_app()


@pytest_asyncio.fixture
async def client(app) -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

import pytest_asyncio


@pytest_asyncio.fixture(scope="session", autouse=True)
async def _cleanup_engine():
    """Dispose the SQLAlchemy engine after all tests to avoid event-loop warnings."""
    yield
    from app.db.session import engine
    try:
        await engine.dispose()
    except Exception:
        pass

