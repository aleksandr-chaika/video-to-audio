from __future__ import annotations

import os
from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import fakeredis.aioredis
import pytest
import pytest_asyncio
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("APP_ENV", "test")
# Force YT_DEMO_MODE off for unit tests (regardless of .env)
os.environ["YT_DEMO_MODE"] = "false"


@pytest.fixture
def tmp_storage(tmp_path: Path) -> Path:
    storage = tmp_path / "mp3craft"
    storage.mkdir(parents=True, exist_ok=True)
    return storage


@pytest_asyncio.fixture
async def fake_redis() -> AsyncIterator[fakeredis.aioredis.FakeRedis]:
    redis = fakeredis.aioredis.FakeRedis(decode_responses=False)
    try:
        yield redis
    finally:
        await redis.aclose()


@pytest_asyncio.fixture
async def fake_queue() -> AsyncIterator[MagicMock]:
    """Mock arq queue (we don't run real workers in tests)."""
    queue = MagicMock()
    queue.enqueue_job = AsyncMock(return_value=MagicMock())
    queue.close = AsyncMock()
    yield queue


@pytest_asyncio.fixture
async def app(
    fake_redis: fakeredis.aioredis.FakeRedis,
    fake_queue: MagicMock,
    tmp_storage: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> AsyncIterator[FastAPI]:
    monkeypatch.setenv("TMP_DIR", str(tmp_storage))

    from app.core.config import get_settings
    get_settings.cache_clear()  # type: ignore[attr-defined]

    from app.core.config import Settings  # noqa: F401  - ensure import after env

    from app.main import create_app

    application = create_app()

    application.state.redis = fake_redis
    application.state.queue = fake_queue

    async def _noop_lifespan(_: Any) -> AsyncIterator[None]:
        yield

    application.router.lifespan_context = _noop_lifespan  # type: ignore[assignment]
    yield application


@pytest_asyncio.fixture
async def client(app: FastAPI) -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
