"""
Shared fixtures for the whole suite. Every test gets a fresh in-memory
SQLite database (function-scoped) — slower than sharing one database
across tests, but eliminates an entire class of cross-test pollution
bugs in exchange for a sub-second cost per test at this project's
current scale.

This conftest is also where every model module gets imported once, so
their tables register on Base.metadata — a test file that only touches
`documents` still needs `flashcards`' tables to exist if any fixture
here touches them indirectly via a foreign key.
"""
import os
import uuid

os.environ.setdefault("SECRET_KEY", "test-secret-key-for-pytest-do-not-use-in-production")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")

import pytest
import pytest_asyncio
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from api.core.db import Base, get_db
from api.core.rate_limit import limiter

# Import every model module so their tables register on Base.metadata.
from api.modules.users import models as users_models
from api.modules.catalog import models as catalog_models
from api.modules.past_papers import models as pp_models
from api.modules.documents import models as doc_models
from api.modules.study_sessions import models as ss_models
from api.modules.progress import models as prog_models
from api.modules.planner import models as planner_models
from api.modules.ai_chat import models as chat_models
from api.modules.flashcards import models as flashcard_models
from api.modules.quizzes import models as quiz_models
from api.modules.mock_exams import models as mock_exam_models
from api.modules.notifications import models as notif_models
from api.modules.credits import models as credit_models
from api.modules.subscriptions import models as sub_models
from api.modules.admin import models as admin_models

from api.main import app


@pytest.fixture(autouse=True)
def reset_rate_limiter():
    """slowapi's limiter is a module-level singleton with in-memory
    storage keyed by client IP — without this, dozens of tests calling
    /auth/register (every test using `registered_user`) would share
    rate-limit state across the whole suite and start failing with 429s
    a few tests in, for reasons that have nothing to do with what each
    individual test is checking."""
    limiter.reset()
    yield


@pytest_asyncio.fixture
async def db_engine():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", connect_args={"check_same_thread": False})
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest.fixture
def session_factory(db_engine):
    return async_sessionmaker(db_engine, expire_on_commit=False)


@pytest.fixture
def client(session_factory):
    async def override_get_db():
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def registered_user(client):
    """Registers a fresh user via the real HTTP endpoint (not a direct
    DB insert) so every test that uses this fixture also exercises
    real registration + password hashing — the exact path Phase 17
    found broken."""
    email = f"user-{uuid.uuid4().hex[:8]}@test.com"
    response = client.post("/api/v1/auth/register", json={"email": email, "password": "supersecret1"})
    assert response.status_code == 200, response.text
    data = response.json()["data"]
    return {
        "email": email,
        "access_token": data["access_token"],
        "headers": {"Authorization": f"Bearer {data['access_token']}"},
    }


@pytest.fixture
def admin_user(client, session_factory, registered_user):
    """Elevates the registered user to admin by writing directly to the
    database — there is deliberately no in-app endpoint that can do
    this (see core/deps.py::get_current_admin_user)."""
    import asyncio

    async def _elevate():
        async with session_factory() as session:
            result = await session.execute(
                select(users_models.User).where(users_models.User.email == registered_user["email"])
            )
            user = result.scalar_one()
            user.role = "admin"
            await session.commit()

    asyncio.run(_elevate())
    return registered_user


def make_valid_description(topic: str = "this subject") -> str:
    """A 500+ word description with no repeated sentence (which would
    otherwise trip the Phase 4 spam-repetition filter — varied content
    is what a real contributor's description actually looks like)."""
    return " ".join(
        f"This section discusses aspect number {i} of {topic}, covering relevant "
        f"details, examples, and context that a student preparing for an exam "
        f"would find useful when studying this material in depth."
        for i in range(20)
    )


def make_valid_pdf_bytes() -> bytes:
    """A genuinely valid (if blank) PDF — the Phase 5 extraction
    pipeline correctly rejects malformed bytes with a safe error, so
    any test that expects `submit` to reach UnderReview/NeedsRevision
    (rather than a hard extraction failure) needs real PDF bytes, not
    a `b"%PDF-1.4 ..."` placeholder that only looks like one."""
    import io
    from pypdf import PdfWriter

    writer = PdfWriter()
    writer.add_blank_page(width=200, height=200)
    buffer = io.BytesIO()
    writer.write(buffer)
    return buffer.getvalue()
