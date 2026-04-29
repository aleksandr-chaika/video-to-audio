from __future__ import annotations

import shutil
import uuid
from pathlib import Path
from typing import Any

from arq.connections import ArqRedis  # type: ignore[import-untyped]

from app.core.config import get_settings
from app.core.errors import (
    JobFailedError,
    JobNotFoundError,
    JobNotReadyError,
)
from app.core.logging import get_logger
from app.domain.job import Job, JobStatus
from app.repositories.job_repository import JobRepositoryProtocol

logger = get_logger(__name__)


class YouTubeService:
    """Orchestration: create job, query status, return file path, cleanup."""

    def __init__(
        self,
        repo: JobRepositoryProtocol,
        queue: ArqRedis,
        tmp_dir: Path | None = None,
    ) -> None:
        self._repo = repo
        self._queue = queue
        self._tmp_dir = tmp_dir or get_settings().tmp_dir

    async def create_job(self, url: str) -> Job:
        job = Job(job_id=str(uuid.uuid4()), url=url)
        await self._repo.save(job)
        await self._queue.enqueue_job(
            "extract_audio_task",
            job.job_id,
            url,
            _job_timeout=get_settings().job_timeout_sec,
        )
        logger.info("job_created", job_id=job.job_id, url=url)
        return job

    async def get_job(self, job_id: str) -> Job:
        job = await self._repo.get(job_id)
        if job is None:
            raise JobNotFoundError()
        return job

    async def get_file_path(self, job_id: str) -> Path:
        job = await self.get_job(job_id)
        if job.status == JobStatus.FAILED:
            raise JobFailedError(message=job.error_message or "Конвертация не удалась")
        if job.status != JobStatus.COMPLETED or not job.file_path:
            raise JobNotReadyError()
        path = Path(job.file_path)
        if not path.exists():
            raise JobNotFoundError(message="Файл удалён или просрочен")
        return path

    async def delete_job(self, job_id: str) -> None:
        job = await self._repo.get(job_id)
        if job is None:
            return
        await self._repo.delete(job_id)
        job_dir = self._tmp_dir / job_id
        if job_dir.exists():
            shutil.rmtree(job_dir, ignore_errors=True)
        logger.info("job_deleted", job_id=job_id)

    def to_status_dict(self, job: Job) -> dict[str, Any]:
        return {
            "job_id": job.job_id,
            "status": job.status,
            "progress": job.progress,
            "title": job.title,
            "thumbnail_url": job.thumbnail_url,
            "duration_sec": job.duration_sec,
            "error_code": job.error_code,
            "error_message": job.error_message,
        }
