from __future__ import annotations

import asyncio
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest

from app.core.errors import ConversionError
from app.services.audio_converter import AudioConverter


class _FakeProcess:
    def __init__(self, returncode: int, stderr: bytes = b"") -> None:
        self.returncode = returncode
        self._stderr = stderr

    async def communicate(self) -> tuple[bytes, bytes]:
        return b"", self._stderr


@pytest.mark.asyncio
async def test_to_wav_raises_when_source_missing(tmp_storage: Path) -> None:
    converter = AudioConverter(ffmpeg_bin="ffmpeg")
    with pytest.raises(ConversionError):
        await converter.to_wav(tmp_storage / "missing.mp3", tmp_storage / "out.wav")


@pytest.mark.asyncio
async def test_to_wav_raises_when_ffmpeg_fails(tmp_storage: Path) -> None:
    src = tmp_storage / "src.mp3"
    src.write_bytes(b"fake")
    target = tmp_storage / "out.wav"
    converter = AudioConverter(ffmpeg_bin="ffmpeg")

    fake = _FakeProcess(returncode=1, stderr=b"bad")
    with patch.object(asyncio, "create_subprocess_exec", AsyncMock(return_value=fake)):
        with pytest.raises(ConversionError):
            await converter.to_wav(src, target)


@pytest.mark.asyncio
async def test_to_wav_succeeds_when_ffmpeg_ok(tmp_storage: Path) -> None:
    src = tmp_storage / "src.mp3"
    src.write_bytes(b"fake")
    target = tmp_storage / "out.wav"
    converter = AudioConverter(ffmpeg_bin="ffmpeg")

    async def _fake_exec(*_args: object, **_kwargs: object) -> _FakeProcess:
        target.write_bytes(b"RIFF" + b"x" * 100)
        return _FakeProcess(returncode=0)

    with patch.object(asyncio, "create_subprocess_exec", _fake_exec):
        result = await converter.to_wav(src, target)
    assert result == target
    assert target.exists()
