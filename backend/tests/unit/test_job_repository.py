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


@pytest.mark.asyncio
async def test_get_returns_none_on_invalid_json(fake_redis: object) -> None:
    """schema-drift / повреждение payload не должно приводить к 500."""
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await fake_redis.set("mp3craft:job:badjson", "not json")  # type: ignore[attr-defined]
    assert await repo.get("badjson") is None


@pytest.mark.asyncio
async def test_get_returns_none_on_schema_mismatch(fake_redis: object) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await fake_redis.set(  # type: ignore[attr-defined]
        "mp3craft:job:schema", '{"unexpected": "shape"}'
    )
    assert await repo.get("schema") is None


@pytest.mark.asyncio
async def test_get_returns_none_on_invalid_status_value(fake_redis: object) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await fake_redis.set(  # type: ignore[attr-defined]
        "mp3craft:job:badstatus",
        '{"job_id":"x","url":"u","status":"WAT","progress":0}',
    )
    assert await repo.get("badstatus") is None
