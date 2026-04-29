import pytest
from pydantic import ValidationError

from app.schemas.youtube import JobCreateRequest


def test_accepts_youtube_com() -> None:
    req = JobCreateRequest(url="https://youtube.com/watch?v=abc", format="wav")  # type: ignore[arg-type]
    assert "youtube.com" in str(req.url)


def test_accepts_youtu_be() -> None:
    req = JobCreateRequest(url="https://youtu.be/abc", format="wav")  # type: ignore[arg-type]
    assert "youtu.be" in str(req.url)


def test_rejects_non_youtube_host() -> None:
    with pytest.raises(ValidationError):
        JobCreateRequest(url="https://example.com/x", format="wav")  # type: ignore[arg-type]


def test_rejects_non_wav_format() -> None:
    with pytest.raises(ValidationError):
        JobCreateRequest(url="https://youtube.com/watch?v=x", format="mp3")  # type: ignore[arg-type]


def test_format_normalizes_case() -> None:
    req = JobCreateRequest(url="https://youtube.com/watch?v=x", format="WAV")  # type: ignore[arg-type]
    assert req.format == "wav"
