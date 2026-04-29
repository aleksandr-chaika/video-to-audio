from __future__ import annotations

from pathlib import Path
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.core.errors import JobFailedError, JobNotFoundError, JobNotReadyError
from app.domain.job import ErrorCode, Job, JobStatus
from app.repositories.job_repository import RedisJobRepository
from app.services.youtube_service import YouTubeService


def _make_service(redis: object, tmp_dir: Path) -> tuple[YouTubeService, MagicMock]:
    repo = RedisJobRepository(redis, ttl_sec=60)  # type: ignore[arg-type]
    queue = MagicMock()
    queue.enqueue_job = AsyncMock()
    return YouTubeService(repo=repo, queue=queue, tmp_dir=tmp_dir), queue


@pytest.mark.asyncio
async def test_create_job_enqueues_and_persists(
    fake_redis: object, tmp_storage: Path
) -> None:
    service, queue = _make_service(fake_redis, tmp_storage)
    job = await service.create_job("https://youtube.com/watch?v=x")
    assert job.status == JobStatus.PENDING
    queue.enqueue_job.assert_awaited_once()
    fetched = await service.get_job(job.job_id)
    assert fetched.job_id == job.job_id


@pytest.mark.asyncio
async def test_get_job_raises_when_missing(
    fake_redis: object, tmp_storage: Path
) -> None:
    service, _ = _make_service(fake_redis, tmp_storage)
    with pytest.raises(JobNotFoundError):
        await service.get_job("nope")


@pytest.mark.asyncio
async def test_get_file_path_raises_when_not_ready(
    fake_redis: object, tmp_storage: Path
) -> None:
    service, _ = _make_service(fake_redis, tmp_storage)
    job = await service.create_job("https://youtube.com/watch?v=x")
    with pytest.raises(JobNotReadyError):
        await service.get_file_path(job.job_id)


@pytest.mark.asyncio
async def test_get_file_path_raises_when_failed(
    fake_redis: object, tmp_storage: Path
) -> None:
    service, _ = _make_service(fake_redis, tmp_storage)
    repo = service._repo  # noqa: SLF001
    job = Job(
        job_id="f",
        url="https://youtube.com/watch?v=x",
        status=JobStatus.FAILED,
        error_code=ErrorCode.BOT_DETECTED,
        error_message="bot",
    )
    await repo.save(job)
    with pytest.raises(JobFailedError):
        await service.get_file_path("f")


@pytest.mark.asyncio
async def test_get_file_path_returns_when_ready(
    fake_redis: object, tmp_storage: Path
) -> None:
    service, _ = _make_service(fake_redis, tmp_storage)
    output = tmp_storage / "out.wav"
    output.write_bytes(b"RIFFsomething")
    repo = service._repo  # noqa: SLF001
    await repo.save(
        Job(
            job_id="ok",
            url="https://youtube.com/watch?v=x",
            status=JobStatus.COMPLETED,
            file_path=str(output),
        )
    )
    path = await service.get_file_path("ok")
    assert path == output


@pytest.mark.asyncio
async def test_delete_job_removes_record(
    fake_redis: object, tmp_storage: Path
) -> None:
    service, _ = _make_service(fake_redis, tmp_storage)
    job = await service.create_job("https://youtube.com/watch?v=x")
    job_dir = tmp_storage / job.job_id
    job_dir.mkdir()
    (job_dir / "output.wav").write_bytes(b"x")
    await service.delete_job(job.job_id)
    assert not job_dir.exists()
    with pytest.raises(JobNotFoundError):
        await service.get_job(job.job_id)
