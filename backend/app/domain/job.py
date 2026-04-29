from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from enum import StrEnum
from typing import Any


class JobStatus(StrEnum):
    PENDING = "pending"
    DOWNLOADING = "downloading"
    CONVERTING = "converting"
    COMPLETED = "completed"
    FAILED = "failed"


class ErrorCode(StrEnum):
    UNAVAILABLE = "UNAVAILABLE"
    GEO_BLOCKED = "GEO_BLOCKED"
    BOT_DETECTED = "BOT_DETECTED"
    EXTRACTION_FAILED = "EXTRACTION_FAILED"
    CONVERSION_FAILED = "CONVERSION_FAILED"
    TIMEOUT = "TIMEOUT"


@dataclass(slots=True)
class Job:
    job_id: str
    url: str
    status: JobStatus = JobStatus.PENDING
    progress: int = 0
    title: str | None = None
    thumbnail_url: str | None = None
    duration_sec: int | None = None
    file_path: str | None = None
    error_code: ErrorCode | None = None
    error_message: str | None = None
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))

    def touch(self) -> None:
        self.updated_at = datetime.now(UTC)

    def to_dict(self) -> dict[str, Any]:
        d = asdict(self)
        d["status"] = self.status.value
        d["error_code"] = self.error_code.value if self.error_code else None
        d["created_at"] = self.created_at.isoformat()
        d["updated_at"] = self.updated_at.isoformat()
        return d

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Job:
        return cls(
            job_id=data["job_id"],
            url=data["url"],
            status=JobStatus(data["status"]),
            progress=int(data.get("progress", 0)),
            title=data.get("title"),
            thumbnail_url=data.get("thumbnail_url"),
            duration_sec=data.get("duration_sec"),
            file_path=data.get("file_path"),
            error_code=(
                ErrorCode(data["error_code"]) if data.get("error_code") else None
            ),
            error_message=data.get("error_message"),
            created_at=_parse_dt(data.get("created_at")),
            updated_at=_parse_dt(data.get("updated_at")),
        )


def _parse_dt(value: str | None) -> datetime:
    if not value:
        return datetime.now(UTC)
    return datetime.fromisoformat(value)
