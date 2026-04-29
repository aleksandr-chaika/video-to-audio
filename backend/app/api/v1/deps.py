from __future__ import annotations

from collections.abc import AsyncGenerator
from typing import Annotated

from arq import create_pool  # type: ignore[import-untyped]
from arq.connections import ArqRedis, RedisSettings  # type: ignore[import-untyped]
from fastapi import Depends, Request
from redis.asyncio import Redis

from app.core.config import Settings, get_settings
from app.repositories.job_repository import RedisJobRepository
from app.services.youtube_service import YouTubeService


def settings_dep() -> Settings:
    return get_settings()


SettingsDep = Annotated[Settings, Depends(settings_dep)]


async def redis_dep(request: Request) -> Redis:
    redis: Redis = request.app.state.redis
    return redis


RedisDep = Annotated[Redis, Depends(redis_dep)]


async def queue_dep(request: Request) -> ArqRedis:
    pool: ArqRedis = request.app.state.queue
    return pool


QueueDep = Annotated[ArqRedis, Depends(queue_dep)]


async def youtube_service_dep(
    redis: RedisDep,
    queue: QueueDep,
    settings: SettingsDep,
) -> YouTubeService:
    repo = RedisJobRepository(redis, ttl_sec=settings.job_ttl_sec)
    return YouTubeService(repo=repo, queue=queue, tmp_dir=settings.tmp_dir)


YouTubeServiceDep = Annotated[YouTubeService, Depends(youtube_service_dep)]


async def arq_pool_factory(redis_url: str) -> AsyncGenerator[ArqRedis, None]:
    pool = await create_pool(RedisSettings.from_dsn(redis_url))
    try:
        yield pool
    finally:
        await pool.close()
