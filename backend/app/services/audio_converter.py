from __future__ import annotations

import asyncio
import shutil
from pathlib import Path

from app.core.errors import ConversionError
from app.core.logging import get_logger

logger = get_logger(__name__)


class AudioConverter:
    """Wraps ffmpeg subprocess calls. PCM 16-bit stereo 44.1kHz WAV by default."""

    def __init__(self, ffmpeg_bin: str | None = None) -> None:
        self._ffmpeg = ffmpeg_bin or shutil.which("ffmpeg") or "ffmpeg"

    async def to_wav(
        self,
        source: Path,
        target: Path,
        *,
        sample_rate: int = 44100,
        channels: int = 2,
    ) -> Path:
        if not source.exists():
            raise ConversionError(message=f"Исходный файл не найден: {source}")
        target.parent.mkdir(parents=True, exist_ok=True)

        cmd = [
            self._ffmpeg,
            "-y",
            "-loglevel", "error",
            "-i", str(source),
            "-vn",
            "-acodec", "pcm_s16le",
            "-ar", str(sample_rate),
            "-ac", str(channels),
            str(target),
        ]
        logger.info("ffmpeg_start", source=str(source), target=str(target))
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        _, stderr = await proc.communicate()
        if proc.returncode != 0:
            err = stderr.decode("utf-8", errors="replace")[:500]
            logger.warning("ffmpeg_failed", returncode=proc.returncode, err=err)
            raise ConversionError(message=f"ffmpeg exit={proc.returncode}: {err}")
        if not target.exists() or target.stat().st_size == 0:
            raise ConversionError(message="ffmpeg создал пустой файл")
        logger.info("ffmpeg_done", target=str(target), size=target.stat().st_size)
        return target
