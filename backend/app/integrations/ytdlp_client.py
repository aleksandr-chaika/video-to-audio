from __future__ import annotations

import asyncio
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from yt_dlp import YoutubeDL  # type: ignore[import-untyped]
from yt_dlp.utils import (  # type: ignore[import-untyped]
    DownloadError,
    ExtractorError,
    GeoRestrictedError,
)

from app.core.config import get_settings
from app.core.errors import (
    BotDetectedError,
    YouTubeUnavailableError,
)
from app.core.logging import get_logger
from app.domain.job import ErrorCode

logger = get_logger(__name__)

_BOT_HINTS = (
    "Sign in to confirm",
    "confirm you're not a bot",
    "bot",
)


@dataclass(slots=True)
class YouTubeMetadata:
    title: str | None
    thumbnail_url: str | None
    duration_sec: int | None
    source_path: Path


class YtDlpClient:
    """Async wrapper around yt-dlp executed in a thread."""

    def __init__(self, output_dir: Path | None = None) -> None:
        self._output_dir = output_dir or get_settings().tmp_dir
        self._cookies = get_settings().yt_cookies_path or None
        self._proxy = get_settings().yt_proxy or None

    async def download_audio(self, url: str, job_id: str) -> YouTubeMetadata:
        """Download best audio stream + return metadata. Conversion is done elsewhere."""
        target_dir = self._output_dir / job_id
        target_dir.mkdir(parents=True, exist_ok=True)

        opts: dict[str, Any] = {
            "format": "bestaudio/best",
            "outtmpl": str(target_dir / "source.%(ext)s"),
            "quiet": True,
            "no_warnings": True,
            "noprogress": True,
            "noplaylist": True,
            "restrictfilenames": True,
            "retries": 2,
            "fragment_retries": 2,
            "extractor_retries": 2,
            "socket_timeout": 30,
        }
        if self._cookies:
            opts["cookiefile"] = self._cookies
        if self._proxy:
            opts["proxy"] = self._proxy

        return await asyncio.to_thread(self._extract_sync, url, opts, target_dir)

    def _extract_sync(self, url: str, opts: dict[str, Any], target_dir: Path) -> YouTubeMetadata:
        try:
            with YoutubeDL(opts) as ydl:
                info = ydl.extract_info(url, download=True)
                if info is None:
                    raise YouTubeUnavailableError(
                        message="yt-dlp вернул пустой ответ",
                        code=ErrorCode.EXTRACTION_FAILED.value,
                    )
                source_filename = ydl.prepare_filename(info)
        except GeoRestrictedError as exc:
            logger.warning("yt_geo_blocked", url=url, err=str(exc))
            raise YouTubeUnavailableError(
                message="Видео недоступно в данном регионе",
                code=ErrorCode.GEO_BLOCKED.value,
            ) from exc
        except (DownloadError, ExtractorError) as exc:
            text = str(exc)
            if any(hint.lower() in text.lower() for hint in _BOT_HINTS):
                logger.warning("yt_bot_detected", url=url, err=text)
                raise BotDetectedError() from exc
            logger.warning("yt_download_error", url=url, err=text)
            raise YouTubeUnavailableError(
                message=f"yt-dlp: {text[:200]}",
                code=ErrorCode.EXTRACTION_FAILED.value,
            ) from exc

        source_path = Path(source_filename)
        if not source_path.exists():
            # yt-dlp может вернуть имя без правильного расширения (post-processor),
            # ищем в job-dir; должен быть ровно один файл, иначе считаем download
            # неуспешным и не угадываем.
            candidates = sorted(target_dir.glob("source.*"))
            if len(candidates) != 1:
                logger.warning(
                    "yt_source_file_ambiguous",
                    job_id=target_dir.name,
                    found=[c.name for c in candidates],
                )
                raise YouTubeUnavailableError(
                    message="yt-dlp: не удалось определить файл-источник",
                    code=ErrorCode.EXTRACTION_FAILED.value,
                )
            source_path = candidates[0]

        return YouTubeMetadata(
            title=str(info.get("title")) if info.get("title") else None,
            thumbnail_url=(str(info.get("thumbnail")) if info.get("thumbnail") else None),
            duration_sec=(int(info.get("duration")) if info.get("duration") is not None else None),
            source_path=source_path,
        )
