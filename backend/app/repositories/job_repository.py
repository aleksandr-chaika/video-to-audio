from __future__ import annotations

import json
from typing import Protocol

from redis.asyncio import Redis

from app.core.config import get_settings
from app.core.logging import get_logger
from app.domain.job import Job

logger = get_logger(__name__)


class JobRepositoryProtocol(Protocol):
    async def save(self, job: Job) -> None: ...
    async def get(self, job_id: str) -> Job | None: ...
    async def delete(self, job_id: str) -> bool: ...


class RedisJobRepository:
    """Stores Job records in Redis with TTL."""

    KEY_PREFIX = "mp3craft:job:"

    def __init__(self, redis: Redis, ttl_sec: int | None = None) -> None:
        self._redis = redis
        self._ttl = ttl_sec or get_settings().job_ttl_sec

    def _key(self, job_id: str) -> str:
        return f"{self.KEY_PREFIX}{job_id}"

    async def save(self, job: Job) -> None:
        job.touch()
        payload = json.dumps(job.to_dict(), ensure_ascii=False)
        await self._redis.set(self._key(job.job_id), payload, ex=self._ttl)

    async def get(self, job_id: str) -> Job | None:
        raw = await self._redis.get(self._key(job_id))
        if raw is None:
            return None
        if isinstance(raw, bytes):
            raw = raw.decode("utf-8")
        try:
            data = json.loads(raw)
            return Job.from_dict(data)
        except (json.JSONDecodeError, KeyError, ValueError, TypeError) as exc:
            # schema-drift / повреждённый payload: трактуем как "записи нет",
            # чтобы пользователь получил понятный 404 вместо 500.
            logger.warning(
                "job_payload_invalid",
                job_id=job_id,
                error=str(exc),
                error_type=type(exc).__name__,
            )
            return None

    async def delete(self, job_id: str) -> bool:
        deleted = await self._redis.delete(self._key(job_id))
        return bool(deleted)
