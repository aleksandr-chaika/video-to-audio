from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from arq import create_pool  # type: ignore[import-untyped]
from arq.connections import RedisSettings  # type: ignore[import-untyped]
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from redis.asyncio import Redis
from slowapi.middleware import SlowAPIMiddleware

from app.api.v1.endpoints import health, youtube
from app.core.config import get_settings
from app.core.errors import register_exception_handlers
from app.core.logging import configure_logging, get_logger
from app.core.rate_limit import limiter

logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    configure_logging(settings.log_level)
    settings.tmp_dir.mkdir(parents=True, exist_ok=True)

    app.state.redis = Redis.from_url(settings.redis_url, decode_responses=False)
    app.state.queue = await create_pool(RedisSettings.from_dsn(settings.redis_url))
    logger.info("api_started", env=settings.app_env)

    try:
        yield
    finally:
        await app.state.queue.close()
        await app.state.redis.aclose()
        logger.info("api_shutdown")


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="MP3 Craft API",
        version="0.1.0",
        description="YouTube → WAV extraction service",
        lifespan=lifespan,
        docs_url="/docs" if settings.is_dev else None,
        redoc_url="/redoc" if settings.is_dev else None,
    )

    app.state.limiter = limiter
    app.add_middleware(SlowAPIMiddleware)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )

    register_exception_handlers(app)

    app.include_router(health.router, prefix="/api/v1")
    app.include_router(youtube.router, prefix="/api/v1")

    return app


app = create_app()
