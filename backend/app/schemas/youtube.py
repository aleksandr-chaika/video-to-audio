from urllib.parse import urlparse

from pydantic import BaseModel, Field, HttpUrl, field_validator

from app.core.config import get_settings
from app.domain.job import ErrorCode, JobStatus


class JobCreateRequest(BaseModel):
    url: HttpUrl = Field(..., description="YouTube video URL")
    format: str = Field(default="wav", description="Output audio format")

    @field_validator("url")
    @classmethod
    def _validate_host(cls, value: HttpUrl) -> HttpUrl:
        allowed = set(get_settings().allowed_hosts)
        host = urlparse(str(value)).hostname or ""
        if host.lower() not in {h.lower() for h in allowed}:
            raise ValueError(
                f"URL host '{host}' is not allowed. Allowed: {sorted(allowed)}"
            )
        return value

    @field_validator("format")
    @classmethod
    def _validate_format(cls, value: str) -> str:
        normalized = value.lower().strip()
        if normalized != "wav":
            raise ValueError("Only 'wav' output format is supported")
        return normalized


class JobCreateResponse(BaseModel):
    job_id: str
    status: JobStatus


class JobStatusResponse(BaseModel):
    job_id: str
    status: JobStatus
    progress: int = 0
    title: str | None = None
    thumbnail_url: str | None = None
    duration_sec: int | None = None
    error_code: ErrorCode | None = None
    error_message: str | None = None
