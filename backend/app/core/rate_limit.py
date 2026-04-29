from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import get_settings

settings = get_settings()

limiter = Limiter(key_func=get_remote_address, default_limits=[])

RATE_LIMIT_CREATE = settings.rate_limit_create
RATE_LIMIT_STATUS = settings.rate_limit_status
