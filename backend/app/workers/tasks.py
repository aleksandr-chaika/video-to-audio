from __future__ import annotations

from pathlib import Path
from typing import Any

from app.core.config import get_settings
from app.core.errors import (
    AppError,
    BotDetectedError,
    ConversionError,
    YouTubeUnavailableError,
)
from app.core.logging import get_logger
from app.domain.job import ErrorCode, Job, JobStatus
from app.integrations.ytdlp_client import YtDlpClient
from app.repositories.job_repository import RedisJobRepository
from app.services.audio_converter import AudioConverter

logger = get_logger(__name__)


async def extract_audio_task(ctx: dict[str, Any], job_id: str, url: str) -> None:
    """Worker job: download audio + convert to WAV. Updates Job state in Redis."""
    repo: RedisJobRepository = ctx["job_repo"]
    ydl: YtDlpClient = ctx["ytdlp_client"]
    converter: AudioConverter = ctx["converter"]
    tmp_dir: Path = ctx["tmp_dir"]

    job = await repo.get(job_id)
    if job is None:
        logger.warning("worker_job_missing", job_id=job_id)
        return

    try:
        await _set_status(repo, job, JobStatus.DOWNLOADING, progress=10)

        meta = await ydl.download_audio(url, job_id)
        job.title = meta.title
        job.thumbnail_url = meta.thumbnail_url
        job.duration_sec = meta.duration_sec
        await _set_status(repo, job, JobStatus.CONVERTING, progress=60)

        target = tmp_dir / job_id / "output.wav"
        await converter.to_wav(meta.source_path, target)

        job.file_path = str(target)
        await _set_status(repo, job, JobStatus.COMPLETED, progress=100)
        logger.info("worker_job_completed", job_id=job_id)

    except BotDetectedError as exc:
        await _fail(repo, job, ErrorCode.BOT_DETECTED, str(exc))
    except YouTubeUnavailableError as exc:
        code = (
            ErrorCode(exc.code)
            if exc.code in ErrorCode.__members__
            else ErrorCode.EXTRACTION_FAILED
        )
        await _fail(repo, job, code, exc.message)
    except ConversionError as exc:
        await _fail(repo, job, ErrorCode.CONVERSION_FAILED, exc.message)
    except TimeoutError:
        logger.warning("worker_job_timeout", job_id=job_id)
        await _fail(repo, job, ErrorCode.TIMEOUT, "Превышено время обработки")
        raise  # arq должен видеть таймаут, чтобы корректно отметить job
    except AppError as exc:
        # любая прочая доменная ошибка — фейлим job и продолжаем worker.
        logger.warning("worker_app_error", job_id=job_id, code=exc.code)
        await _fail(repo, job, ErrorCode.EXTRACTION_FAILED, exc.message)
    except Exception as exc:  # pragma: no cover — defensive last-resort
        # ВАЖНО: не ловим BaseException — это бы проглотило
        # asyncio.CancelledError/SystemExit и сломало graceful shutdown воркера.
        logger.exception("worker_unexpected_error", job_id=job_id)
        await _fail(repo, job, ErrorCode.EXTRACTION_FAILED, str(exc))


async def cleanup_old_jobs(ctx: dict[str, Any]) -> None:
    """Cron job: remove temp directories older than TTL."""
    import asyncio

    tmp_dir: Path = ctx["tmp_dir"]
    ttl_sec = get_settings().job_ttl_sec
    removed = await asyncio.to_thread(_cleanup_sync, tmp_dir, ttl_sec)
    if removed:
        logger.info("cleanup_done", removed=removed)


def _cleanup_sync(tmp_dir: Path, ttl_sec: int) -> int:
    import shutil
    import time

    if not tmp_dir.exists():
        return 0
    now = time.time()
    removed = 0
    for child in tmp_dir.iterdir():
        try:
            if child.is_dir() and now - child.stat().st_mtime > ttl_sec:
                shutil.rmtree(child, ignore_errors=True)
                removed += 1
        except OSError:
            continue
    return removed


async def _set_status(
    repo: RedisJobRepository,
    job: Job,
    status: JobStatus,
    *,
    progress: int,
) -> None:
    job.status = status
    job.progress = progress
    await repo.save(job)


async def _fail(repo: RedisJobRepository, job: Job, code: ErrorCode, message: str) -> None:
    job.status = JobStatus.FAILED
    job.error_code = code
    job.error_message = message
    job.progress = 100
    await repo.save(job)
    logger.warning("worker_job_failed", job_id=job.job_id, code=code.value, msg=message)
