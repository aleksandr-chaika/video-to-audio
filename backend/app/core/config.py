from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

_DEFAULT_HOSTS = (
    "youtube.com,youtu.be,m.youtube.com,www.youtube.com,music.youtube.com"
)


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

    # Stored as comma-separated string in env to avoid JSON-parsing surprises
    # of pydantic-settings for list[str] fields.
    allowed_hosts_raw: str = _DEFAULT_HOSTS
    cors_origins_raw: str = "*"

    yt_cookies_path: str | None = None
    yt_proxy: str | None = None

    @property
    def allowed_hosts(self) -> list[str]:
        return [h.strip().lower() for h in self.allowed_hosts_raw.split(",") if h.strip()]

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.cors_origins_raw.split(",") if o.strip()]

    @property
    def is_dev(self) -> bool:
        return self.app_env == "dev"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
