from __future__ import annotations

from typing import Any, ClassVar

from arq.connections import RedisSettings  # type: ignore[import-untyped]
from arq.cron import cron  # type: ignore[import-untyped]
from redis.asyncio import Redis

from app.core.config import get_settings
from app.core.logging import configure_logging, get_logger
from app.integrations.ytdlp_client import YtDlpClient
from app.repositories.job_repository import RedisJobRepository
from app.services.audio_converter import AudioConverter
from app.workers.tasks import cleanup_old_jobs, extract_audio_task

logger = get_logger(__name__)


async def _startup(ctx: dict[str, Any]) -> None:
    settings = get_settings()
    configure_logging(settings.log_level)
    settings.tmp_dir.mkdir(parents=True, exist_ok=True)
    redis = Redis.from_url(settings.redis_url, decode_responses=False)
    ctx["redis"] = redis
    ctx["job_repo"] = RedisJobRepository(redis, ttl_sec=settings.job_ttl_sec)
    ctx["ytdlp_client"] = YtDlpClient(output_dir=settings.tmp_dir)
    ctx["converter"] = AudioConverter()
    ctx["tmp_dir"] = settings.tmp_dir
    logger.info("worker_started")


async def _shutdown(ctx: dict[str, Any]) -> None:
    redis: Redis = ctx.get("redis")  # type: ignore[assignment]
    if redis is not None:
        await redis.aclose()
    logger.info("worker_shutdown")


def _redis_settings() -> RedisSettings:
    return RedisSettings.from_dsn(get_settings().redis_url)


class WorkerSettings:
    functions: ClassVar[list[Any]] = [extract_audio_task]
    cron_jobs: ClassVar[list[Any]] = [
        cron(cleanup_old_jobs, minute={0, 10, 20, 30, 40, 50}, run_at_startup=True)
    ]
    on_startup = _startup
    on_shutdown = _shutdown
    redis_settings = _redis_settings()
    job_timeout = 300
    keep_result = 60
