from __future__ import annotations

import time
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.core.errors import BotDetectedError, ConversionError, YouTubeUnavailableError
from app.domain.job import ErrorCode, Job, JobStatus
from app.integrations.ytdlp_client import YouTubeMetadata
from app.repositories.job_repository import RedisJobRepository
from app.workers.tasks import _cleanup_sync, cleanup_old_jobs, extract_audio_task


def _make_ctx(
    fake_redis: object, tmp_storage: Path, *, ydl_mock: MagicMock, conv_mock: MagicMock
) -> dict:
    return {
        "job_repo": RedisJobRepository(fake_redis, ttl_sec=60),  # type: ignore[arg-type]
        "ytdlp_client": ydl_mock,
        "converter": conv_mock,
        "tmp_dir": tmp_storage,
    }


@pytest.mark.asyncio
async def test_extract_audio_task_completes(
    fake_redis: object, tmp_storage: Path
) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    job = Job(job_id="ok", url="https://youtube.com/watch?v=x")
    await repo.save(job)

    src = tmp_storage / "ok" / "source.m4a"
    src.parent.mkdir(parents=True, exist_ok=True)
    src.write_bytes(b"x")

    ydl = MagicMock()
    ydl.download_audio = AsyncMock(
        return_value=YouTubeMetadata(
            title="T",
            thumbnail_url="http://x",
            duration_sec=100,
            source_path=src,
        )
    )

    target = tmp_storage / "ok" / "output.wav"

    async def _conv(_s: Path, t: Path, **_kw: object) -> Path:
        t.write_bytes(b"RIFF")
        return t

    conv = MagicMock()
    conv.to_wav = AsyncMock(side_effect=_conv)

    ctx = _make_ctx(fake_redis, tmp_storage, ydl_mock=ydl, conv_mock=conv)
    await extract_audio_task(ctx, "ok", "https://youtube.com/watch?v=x")

    fetched = await repo.get("ok")
    assert fetched is not None
    assert fetched.status == JobStatus.COMPLETED
    assert fetched.title == "T"
    assert fetched.file_path == str(target)


@pytest.mark.asyncio
async def test_extract_audio_task_handles_bot_detected(
    fake_redis: object, tmp_storage: Path
) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await repo.save(Job(job_id="b", url="https://youtube.com/watch?v=x"))

    ydl = MagicMock()
    ydl.download_audio = AsyncMock(side_effect=BotDetectedError())
    conv = MagicMock()
    conv.to_wav = AsyncMock()
    ctx = _make_ctx(fake_redis, tmp_storage, ydl_mock=ydl, conv_mock=conv)

    await extract_audio_task(ctx, "b", "https://youtube.com/watch?v=x")
    fetched = await repo.get("b")
    assert fetched is not None
    assert fetched.status == JobStatus.FAILED
    assert fetched.error_code == ErrorCode.BOT_DETECTED


@pytest.mark.asyncio
async def test_extract_audio_task_handles_unavailable(
    fake_redis: object, tmp_storage: Path
) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await repo.save(Job(job_id="u", url="https://youtube.com/watch?v=x"))

    ydl = MagicMock()
    ydl.download_audio = AsyncMock(
        side_effect=YouTubeUnavailableError(
            message="gone", code=ErrorCode.GEO_BLOCKED.value
        )
    )
    conv = MagicMock()
    ctx = _make_ctx(fake_redis, tmp_storage, ydl_mock=ydl, conv_mock=conv)

    await extract_audio_task(ctx, "u", "https://youtube.com/watch?v=x")
    fetched = await repo.get("u")
    assert fetched is not None
    assert fetched.status == JobStatus.FAILED
    assert fetched.error_code == ErrorCode.GEO_BLOCKED


@pytest.mark.asyncio
async def test_extract_audio_task_handles_conversion_error(
    fake_redis: object, tmp_storage: Path
) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await repo.save(Job(job_id="c", url="https://youtube.com/watch?v=x"))

    src = tmp_storage / "c" / "src.m4a"
    src.parent.mkdir(parents=True)
    src.write_bytes(b"x")

    ydl = MagicMock()
    ydl.download_audio = AsyncMock(
        return_value=YouTubeMetadata(
            title=None, thumbnail_url=None, duration_sec=None, source_path=src
        )
    )
    conv = MagicMock()
    conv.to_wav = AsyncMock(side_effect=ConversionError(message="ffmpeg"))
    ctx = _make_ctx(fake_redis, tmp_storage, ydl_mock=ydl, conv_mock=conv)

    await extract_audio_task(ctx, "c", "https://youtube.com/watch?v=x")
    fetched = await repo.get("c")
    assert fetched is not None
    assert fetched.status == JobStatus.FAILED
    assert fetched.error_code == ErrorCode.CONVERSION_FAILED


@pytest.mark.asyncio
async def test_extract_audio_task_handles_unexpected(
    fake_redis: object, tmp_storage: Path
) -> None:
    repo = RedisJobRepository(fake_redis, ttl_sec=60)  # type: ignore[arg-type]
    await repo.save(Job(job_id="x", url="https://youtube.com/watch?v=x"))

    ydl = MagicMock()
    ydl.download_audio = AsyncMock(side_effect=RuntimeError("boom"))
    conv = MagicMock()
    ctx = _make_ctx(fake_redis, tmp_storage, ydl_mock=ydl, conv_mock=conv)

    await extract_audio_task(ctx, "x", "https://youtube.com/watch?v=x")
    fetched = await repo.get("x")
    assert fetched is not None
    assert fetched.status == JobStatus.FAILED


@pytest.mark.asyncio
async def test_extract_audio_task_returns_when_job_missing(
    fake_redis: object, tmp_storage: Path
) -> None:
    ydl = MagicMock()
    conv = MagicMock()
    ctx = _make_ctx(fake_redis, tmp_storage, ydl_mock=ydl, conv_mock=conv)
    await extract_audio_task(ctx, "missing", "https://youtube.com/watch?v=x")
    ydl.download_audio.assert_not_called()


def test_cleanup_sync_removes_old_dirs(tmp_storage: Path) -> None:
    old = tmp_storage / "old"
    old.mkdir()
    (old / "f.wav").write_bytes(b"x")
    new = tmp_storage / "new"
    new.mkdir()

    old_time = time.time() - 7200
    import os

    os.utime(old, (old_time, old_time))

    removed = _cleanup_sync(tmp_storage, ttl_sec=3600)
    assert removed == 1
    assert not old.exists()
    assert new.exists()


def test_cleanup_sync_returns_zero_when_dir_missing(tmp_path: Path) -> None:
    assert _cleanup_sync(tmp_path / "absent", ttl_sec=3600) == 0


@pytest.mark.asyncio
async def test_cleanup_old_jobs_runs(tmp_storage: Path) -> None:
    ctx = {"tmp_dir": tmp_storage}
    await cleanup_old_jobs(ctx)
