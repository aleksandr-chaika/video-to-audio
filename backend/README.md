# MP3 Craft — Backend (FastAPI)

YouTube → WAV extraction service. Извлекает аудио из YouTube-видео через `yt-dlp`, конвертирует в WAV через `ffmpeg`. Состояние задач хранится в Redis, выполнение — в `arq` worker'е.

## Стек

- **FastAPI** — async API
- **yt-dlp** — извлечение аудио (поддерживает >1000 сайтов, активно поддерживается)
- **ffmpeg** — конвертация в PCM WAV (16-bit, 44.1 kHz)
- **arq** — Redis-based async job queue
- **redis** — состояние задач + брокер
- **slowapi** — rate limiting по IP
- **structlog** — JSON-логи
- Python 3.12+

## Структура

```
app/
├── main.py                         # FastAPI app + lifespan
├── core/                           # config, logging, errors, rate_limit
├── api/v1/endpoints/               # health, youtube
├── schemas/                        # Pydantic v2
├── services/                       # YouTubeService, AudioConverter
├── integrations/                   # YtDlpClient
├── repositories/                   # RedisJobRepository
├── workers/                        # arq tasks + settings
└── domain/                         # Job, JobStatus, ErrorCode
tests/
├── unit/                           # service, repo, converter, schemas
└── integration/                    # endpoints через httpx.AsyncClient + fakeredis
```

## Запуск (через docker compose)

Из корня репо:

```bash
cp backend/.env.example backend/.env
docker compose up --build
```

Поднимется три сервиса: `redis` + `api` (порт 8000) + `worker`.

Проверка:
```bash
curl http://localhost:8000/api/v1/health
```

Swagger UI: http://localhost:8000/docs

## API

| Метод | Путь | Описание |
|---|---|---|
| `POST` | `/api/v1/youtube/jobs` | Создать задачу. Body: `{"url": "...", "format": "wav"}`. 202 + `{job_id, status:"pending"}`. Rate limit: 10/min/IP. |
| `GET` | `/api/v1/youtube/jobs/{id}` | Статус: `pending → downloading → converting → completed | failed`. |
| `GET` | `/api/v1/youtube/jobs/{id}/file` | Скачать WAV. 200 audio/wav, 409 если не готов / failed, 404 если пропал. |
| `DELETE` | `/api/v1/youtube/jobs/{id}` | Удалить задачу + файл. 204. |
| `GET` | `/api/v1/health` | Healthcheck. |

### Ошибочные коды

`{ "detail": "...", "code": "..." }`. Коды: `INVALID_URL`, `JOB_NOT_FOUND`, `JOB_NOT_READY`, `JOB_FAILED`, `BOT_DETECTED`, `YT_UNAVAILABLE`, `RATE_LIMITED`, `VALIDATION_ERROR`.

## Локальная разработка без Docker

```bash
python3.12 -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"

# В одном терминале — Redis (требуется):
redis-server

# В другом — worker:
arq app.workers.arq_settings.WorkerSettings

# В третьем — API:
uvicorn app.main:app --reload
```

## Тесты

```bash
pytest --cov=app --cov-report=term-missing
ruff check app
mypy app --strict
```

Тесты используют `fakeredis` и моки arq-очереди — Redis для них не нужен.

## Production-замечания

- На cloud-IP YouTube часто триггерит «Sign in to confirm you're not a bot». Для прод-деплоя задайте `YT_COOKIES_PATH` (cookies.txt из браузера) и/или `YT_PROXY` (резидентный прокси).
- `JOB_TTL_SEC=3600` — после часа задача и файл удаляются.
- `arq` cron каждые 10 минут чистит каталоги старше TTL.
- Worker timeout = 300 секунд на задачу.

## Безопасность

- Только whitelist YouTube-хостов (см. `ALLOWED_HOSTS` в `.env.example`).
- Файлы лежат в `/tmp/mp3craft/{uuid}/output.wav` — UUID не угадать.
- `X-Content-Type-Options: nosniff` на скачивании.
- Rate limit `slowapi` по IP.
- Никаких секретов в коде, всё через `.env`.
