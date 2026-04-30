from __future__ import annotations

import pytest
from httpx import AsyncClient

from app.domain.job import ErrorCode, Job, JobStatus
from app.repositories.job_repository import RedisJobRepository


@pytest.mark.asyncio
async def test_create_job_returns_202_with_job_id(client: AsyncClient, fake_queue: object) -> None:
    response = await client.post(
        "/api/v1/youtube/jobs",
        json={"url": "https://youtube.com/watch?v=dQw4w9WgXcQ"},
    )
    assert response.status_code == 202
    body = response.json()
    assert "job_id" in body
    assert body["status"] == JobStatus.PENDING.value


@pytest.mark.asyncio
async def test_create_job_rejects_non_youtube_host(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/youtube/jobs",
        json={"url": "https://example.com/watch?v=foo"},
    )
    assert response.status_code == 422
    body = response.json()
    assert body["code"] == "VALIDATION_ERROR"


@pytest.mark.asyncio
async def test_create_job_rejects_invalid_url(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/youtube/jobs",
        json={"url": "not-a-url"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_create_job_rejects_non_wav_format(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/youtube/jobs",
        json={"url": "https://youtube.com/watch?v=abc", "format": "mp3"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_get_job_returns_404_when_missing(client: AsyncClient) -> None:
    response = await client.get("/api/v1/youtube/jobs/nonexistent-id")
    assert response.status_code == 404
    body = response.json()
    assert body["code"] == "JOB_NOT_FOUND"


@pytest.mark.asyncio
async def test_get_job_returns_status(client: AsyncClient, fake_redis: object) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    job = Job(
        job_id="test-job",
        url="https://youtube.com/watch?v=x",
        status=JobStatus.DOWNLOADING,
        progress=42,
        title="Test Title",
        duration_sec=120,
    )
    await repo.save(job)

    response = await client.get("/api/v1/youtube/jobs/test-job")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "downloading"
    assert body["progress"] == 42
    assert body["title"] == "Test Title"


@pytest.mark.asyncio
async def test_download_file_returns_409_when_not_completed(
    client: AsyncClient, fake_redis: object
) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await repo.save(
        Job(
            job_id="not-ready",
            url="https://youtube.com/watch?v=x",
            status=JobStatus.DOWNLOADING,
        )
    )
    response = await client.get("/api/v1/youtube/jobs/not-ready/file")
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_download_file_returns_409_when_failed(
    client: AsyncClient, fake_redis: object
) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await repo.save(
        Job(
            job_id="failed",
            url="https://youtube.com/watch?v=x",
            status=JobStatus.FAILED,
            error_code=ErrorCode.BOT_DETECTED,
            error_message="Bot detected",
        )
    )
    response = await client.get("/api/v1/youtube/jobs/failed/file")
    assert response.status_code == 409
    assert response.json()["code"] == "JOB_FAILED"


@pytest.mark.asyncio
async def test_delete_job_removes_record(client: AsyncClient, fake_redis: object) -> None:
    import uuid

    job_id = str(uuid.uuid4())
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await repo.save(
        Job(
            job_id=job_id,
            url="https://youtube.com/watch?v=x",
            status=JobStatus.COMPLETED,
            file_path="/tmp/nonexistent",
        )
    )
    response = await client.delete(f"/api/v1/youtube/jobs/{job_id}")
    assert response.status_code == 204
    assert await repo.get(job_id) is None


# ---- regression: path traversal / file_path вне tmp_dir (BE-1) ---------------


@pytest.mark.asyncio
async def test_download_file_rejects_path_outside_tmp_dir(
    client: AsyncClient, fake_redis: object
) -> None:
    """defence-in-depth: даже если worker / атакующий записал в Redis путь
    за пределами tmp_dir, endpoint должен вернуть 404, а не отдать файл."""
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await repo.save(
        Job(
            job_id="malicious",
            url="https://youtube.com/watch?v=x",
            status=JobStatus.COMPLETED,
            file_path="/etc/passwd",
        )
    )
    response = await client.get("/api/v1/youtube/jobs/malicious/file")
    assert response.status_code == 404
    assert response.json()["code"] == "JOB_NOT_FOUND"


@pytest.mark.asyncio
async def test_delete_job_with_invalid_id_is_noop(client: AsyncClient) -> None:
    """job_id, не являющийся UUIDv4, не должен приводить к попытке rmtree.
    Endpoint просто молча возвращает 204 (idempotency)."""
    response = await client.delete("/api/v1/youtube/jobs/not-a-uuid")
    assert response.status_code == 204


# ---- regression: schema-drift / повреждённый payload в Redis (BE-3) ---------


@pytest.mark.asyncio
async def test_get_job_returns_404_when_redis_payload_corrupted(
    client: AsyncClient, fake_redis: object
) -> None:
    """Если в Redis лежит невалидный JSON (или JSON с чужой схемой), endpoint
    обязан ответить 404, а не упасть в 500."""
    await fake_redis.set(  # type: ignore[attr-defined]
        "mp3craft:job:broken", '{"this": "is not a job"}'
    )
    response = await client.get("/api/v1/youtube/jobs/broken")
    assert response.status_code == 404
    assert response.json()["code"] == "JOB_NOT_FOUND"


@pytest.mark.asyncio
async def test_get_job_returns_404_when_redis_payload_invalid_json(
    client: AsyncClient, fake_redis: object
) -> None:
    await fake_redis.set("mp3craft:job:badjson", "not-json{{{")  # type: ignore[attr-defined]
    response = await client.get("/api/v1/youtube/jobs/badjson")
    assert response.status_code == 404
