from __future__ import annotations

from fastapi import APIRouter, Request, Response, status
from fastapi.responses import FileResponse

from app.api.v1.deps import YouTubeServiceDep
from app.core.rate_limit import RATE_LIMIT_CREATE, RATE_LIMIT_STATUS, limiter
from app.schemas.youtube import (
    JobCreateRequest,
    JobCreateResponse,
    JobStatusResponse,
)

router = APIRouter(prefix="/youtube", tags=["youtube"])


@router.post(
    "/jobs",
    status_code=status.HTTP_202_ACCEPTED,
    response_model=JobCreateResponse,
    summary="Создать задачу извлечения аудио из YouTube",
)
@limiter.limit(RATE_LIMIT_CREATE)
async def create_job(
    request: Request,
    payload: JobCreateRequest,
    service: YouTubeServiceDep,
) -> JobCreateResponse:
    _ = request  # required positional arg for slowapi decorator
    job = await service.create_job(str(payload.url))
    return JobCreateResponse(job_id=job.job_id, status=job.status)


@router.get(
    "/jobs/{job_id}",
    response_model=JobStatusResponse,
    summary="Статус задачи",
)
@limiter.limit(RATE_LIMIT_STATUS)
async def get_job(
    request: Request,
    job_id: str,
    service: YouTubeServiceDep,
) -> JobStatusResponse:
    _ = request
    job = await service.get_job(job_id)
    return JobStatusResponse(**service.to_status_dict(job))


@router.get(
    "/jobs/{job_id}/file",
    summary="Скачать сконвертированный WAV",
    response_class=FileResponse,
)
async def download_file(
    job_id: str,
    service: YouTubeServiceDep,
) -> FileResponse:
    path = await service.get_file_path(job_id)
    return FileResponse(
        path=str(path),
        media_type="audio/wav",
        filename=f"{job_id}.wav",
        headers={"X-Content-Type-Options": "nosniff"},
    )


@router.delete(
    "/jobs/{job_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Удалить задачу и файл",
)
async def delete_job(
    job_id: str,
    service: YouTubeServiceDep,
) -> Response:
    await service.delete_job(job_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
