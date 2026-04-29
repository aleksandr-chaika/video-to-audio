from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from app.core.errors import BotDetectedError, YouTubeUnavailableError
from app.integrations.ytdlp_client import YtDlpClient


def _ydl_mock(info: dict | None, *, raises: Exception | None = None) -> MagicMock:
    """Make a mock that mimics `with YoutubeDL(opts) as ydl: ydl.extract_info(...)`."""
    instance = MagicMock()
    if raises is not None:
        instance.extract_info.side_effect = raises
    else:
        instance.extract_info.return_value = info
        instance.prepare_filename.return_value = "/tmp/source.m4a"
    ctx = MagicMock()
    ctx.__enter__.return_value = instance
    ctx.__exit__.return_value = False
    factory = MagicMock(return_value=ctx)
    return factory


@pytest.mark.asyncio
async def test_download_audio_returns_metadata(tmp_storage: Path) -> None:
    fake_file = tmp_storage / "job1" / "source.m4a"
    fake_file.parent.mkdir(parents=True, exist_ok=True)
    fake_file.write_bytes(b"data")

    info = {
        "title": "Sample",
        "thumbnail": "https://i.ytimg.com/x.jpg",
        "duration": 200,
    }
    factory = _ydl_mock(info)
    factory.return_value.__enter__.return_value.prepare_filename.return_value = str(fake_file)

    with patch("app.integrations.ytdlp_client.YoutubeDL", factory):
        client = YtDlpClient(output_dir=tmp_storage)
        meta = await client.download_audio("https://youtube.com/watch?v=x", "job1")

    assert meta.title == "Sample"
    assert meta.duration_sec == 200
    assert meta.source_path == fake_file


@pytest.mark.asyncio
async def test_download_audio_raises_bot_detected(tmp_storage: Path) -> None:
    from yt_dlp.utils import DownloadError  # type: ignore[import-untyped]

    factory = _ydl_mock(None, raises=DownloadError("Sign in to confirm you're not a bot"))
    with patch("app.integrations.ytdlp_client.YoutubeDL", factory):
        client = YtDlpClient(output_dir=tmp_storage)
        with pytest.raises(BotDetectedError):
            await client.download_audio("https://youtube.com/watch?v=x", "j2")


@pytest.mark.asyncio
async def test_download_audio_raises_geo_blocked(tmp_storage: Path) -> None:
    from yt_dlp.utils import GeoRestrictedError  # type: ignore[import-untyped]

    factory = _ydl_mock(None, raises=GeoRestrictedError("Region"))
    with patch("app.integrations.ytdlp_client.YoutubeDL", factory):
        client = YtDlpClient(output_dir=tmp_storage)
        with pytest.raises(YouTubeUnavailableError):
            await client.download_audio("https://youtube.com/watch?v=x", "j3")


@pytest.mark.asyncio
async def test_download_audio_raises_generic(tmp_storage: Path) -> None:
    from yt_dlp.utils import DownloadError  # type: ignore[import-untyped]

    factory = _ydl_mock(None, raises=DownloadError("404 not found"))
    with patch("app.integrations.ytdlp_client.YoutubeDL", factory):
        client = YtDlpClient(output_dir=tmp_storage)
        with pytest.raises(YouTubeUnavailableError):
            await client.download_audio("https://youtube.com/watch?v=x", "j4")


@pytest.mark.asyncio
async def test_download_audio_raises_when_info_none(tmp_storage: Path) -> None:
    factory = _ydl_mock(None)
    with patch("app.integrations.ytdlp_client.YoutubeDL", factory):
        client = YtDlpClient(output_dir=tmp_storage)
        with pytest.raises(YouTubeUnavailableError):
            await client.download_audio("https://youtube.com/watch?v=x", "j5")
