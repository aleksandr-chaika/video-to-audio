import pytest

from app.domain.job import ErrorCode, Job, JobStatus
from app.repositories.job_repository import RedisJobRepository


@pytest.mark.asyncio
async def test_save_and_get_round_trip(fake_redis: object) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    job = Job(
        job_id="abc",
        url="https://youtube.com/watch?v=x",
        status=JobStatus.CONVERTING,
        progress=80,
        title="Hi",
        duration_sec=42,
        error_code=None,
    )
    await repo.save(job)
    fetched = await repo.get("abc")

    assert fetched is not None
    assert fetched.job_id == "abc"
    assert fetched.status == JobStatus.CONVERTING
    assert fetched.progress == 80
    assert fetched.title == "Hi"
    assert fetched.duration_sec == 42


@pytest.mark.asyncio
async def test_get_returns_none_when_missing(fake_redis: object) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    assert await repo.get("missing") is None


@pytest.mark.asyncio
async def test_delete_removes_record(fake_redis: object) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    job = Job(job_id="x", url="https://youtube.com/watch?v=x")
    await repo.save(job)
    assert await repo.delete("x") is True
    assert await repo.get("x") is None


@pytest.mark.asyncio
async def test_error_code_persists(fake_redis: object) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    job = Job(
        job_id="e",
        url="https://youtube.com/watch?v=x",
        status=JobStatus.FAILED,
        error_code=ErrorCode.BOT_DETECTED,
        error_message="bot",
    )
    await repo.save(job)
    fetched = await repo.get("e")
    assert fetched is not None
    assert fetched.error_code == ErrorCode.BOT_DETECTED
    assert fetched.error_message == "bot"
