from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded

from app.core.logging import get_logger

logger = get_logger(__name__)


class AppError(Exception):
    code: str = "INTERNAL_ERROR"
    status_code: int = 500
    message: str = "Внутренняя ошибка"

    def __init__(self, message: str | None = None, *, code: str | None = None) -> None:
        self.message = message or self.message
        self.code = code or self.code
        super().__init__(self.message)


class JobNotFoundError(AppError):
    code = "JOB_NOT_FOUND"
    status_code = 404
    message = "Задача не найдена"


class JobNotReadyError(AppError):
    code = "JOB_NOT_READY"
    status_code = 409
    message = "Задача ещё не завершена"


class JobFailedError(AppError):
    code = "JOB_FAILED"
    status_code = 409
    message = "Задача завершилась с ошибкой"


class InvalidYouTubeUrlError(AppError):
    code = "INVALID_URL"
    status_code = 422
    message = "Некорректный YouTube URL"


class YouTubeUnavailableError(AppError):
    code = "YT_UNAVAILABLE"
    status_code = 503
    message = "YouTube недоступен"


class BotDetectedError(AppError):
    code = "BOT_DETECTED"
    status_code = 503
    message = "YouTube требует подтверждения. Повторите позже."


class ConversionError(AppError):
    code = "CONVERSION_FAILED"
    status_code = 500
    message = "Не удалось сконвертировать аудио"


def _error_response(*, status_code: int, code: str, detail: str) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={"detail": detail, "code": code},
    )


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def _app_error_handler(_: Request, exc: AppError) -> JSONResponse:
        logger.warning("app_error", code=exc.code, message=exc.message)
        return _error_response(
            status_code=exc.status_code, code=exc.code, detail=exc.message
        )

    @app.exception_handler(RequestValidationError)
    async def _validation_handler(
        _: Request, exc: RequestValidationError
    ) -> JSONResponse:
        return _error_response(
            status_code=422,
            code="VALIDATION_ERROR",
            detail=_format_validation(exc.errors()),
        )

    @app.exception_handler(RateLimitExceeded)
    async def _rate_limit_handler(
        _: Request, exc: RateLimitExceeded
    ) -> JSONResponse:
        return _error_response(
            status_code=429,
            code="RATE_LIMITED",
            detail=f"Превышен лимит: {exc.detail}",
        )

    @app.exception_handler(Exception)
    async def _unhandled_handler(_: Request, exc: Exception) -> JSONResponse:
        logger.exception("unhandled_error", error=str(exc))
        return _error_response(
            status_code=500,
            code="INTERNAL_ERROR",
            detail="Внутренняя ошибка сервера",
        )


def _format_validation(errors: list[dict[str, Any]]) -> str:
    parts: list[str] = []
    for err in errors:
        loc = ".".join(str(p) for p in err.get("loc", []) if p != "body")
        msg = err.get("msg", "invalid")
        parts.append(f"{loc}: {msg}" if loc else msg)
    return "; ".join(parts) or "Validation failed"
