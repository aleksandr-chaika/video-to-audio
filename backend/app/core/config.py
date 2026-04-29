from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_env: str = "dev"
    log_level: str = "INFO"
    host: str = "0.0.0.0"
    port: int = 8000

    redis_url: str = "redis://localhost:6379/0"

    job_ttl_sec: int = 3600
    job_timeout_sec: int = 300
    tmp_dir: Path = Path("/tmp/mp3craft")

    rate_limit_create: str = "10/minute"
    rate_limit_status: str = "60/minute"

    allowed_hosts: list[str] = Field(
        default_factory=lambda: [
            "youtube.com",
            "youtu.be",
            "m.youtube.com",
            "www.youtube.com",
            "music.youtube.com",
        ]
    )
    cors_origins: list[str] = Field(default_factory=lambda: ["*"])

    yt_cookies_path: str | None = None
    yt_proxy: str | None = None

    @property
    def is_dev(self) -> bool:
        return self.app_env == "dev"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
