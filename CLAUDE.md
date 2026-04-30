# MP3 Craft — справка для Claude Code

Файл с быстрой ориентацией по проекту: API, окружение, команды, дизайн-токены, известные правила.

---

## 1. Что это за проект

Тестовое приложение «MP3 Craft»: конвертация локальных MP3/MP4/MOV/M4A → WAV (на устройстве) и извлечение аудио из YouTube → WAV (на сервере).

**Стек:**
- Backend: FastAPI + yt-dlp + ffmpeg + arq (Redis-очередь) + slowapi (rate limit) + structlog.
- Mobile: Flutter (iOS + iPad), Clean Architecture, `flutter_bloc` + `get_it` + `injectable` + `sqflite`, `dio`, `just_audio`, `audio_waveforms`, `ffmpeg_kit_flutter_new`, `go_router`, `freezed_annotation`, `dartz`.
- Монорепо: `backend/`, `mobile/`, общий `docker-compose.yml`.

Подробный план: [`docs/plans/image-1-image-2-linear-swing.md`](docs/plans/image-1-image-2-linear-swing.md).

---

## 2. Структура

```
.
├── backend/                    # FastAPI
│   ├── app/
│   │   ├── api/v1/endpoints/   # health.py, youtube.py
│   │   ├── core/               # config, logging, errors, rate_limit
│   │   ├── domain/             # Job dataclass, JobStatus, ErrorCode
│   │   ├── integrations/       # ytdlp_client.py
│   │   ├── repositories/       # job_repository.py (Redis)
│   │   ├── schemas/            # youtube.py, common.py
│   │   ├── services/           # youtube_service.py, audio_converter.py
│   │   └── workers/            # arq_settings.py + tasks.py
│   ├── tests/                  # pytest + httpx + fakeredis (42 теста, coverage 87%)
│   ├── Dockerfile              # multistage python:3.12-slim + ffmpeg
│   ├── pyproject.toml
│   └── .env.example
├── mobile/                     # Flutter
│   ├── lib/
│   │   ├── app/{di,router,theme}/
│   │   ├── core/{error,network,usecase,utils,widgets}/
│   │   └── features/{home,convert,youtube,result,crop,history,settings}/
│   ├── test/                   # unit-тесты блоков и утилит
│   └── pubspec.yaml
├── docs/
│   ├── plans/                  # планы (image-1-image-2-linear-swing.md)
│   ├── api-contract.md         # OpenAPI snapshot
│   └── design-tokens.md        # извлечённые из Figma токены (см. ниже)
├── docker-compose.yml          # api + redis + worker
├── .mcp.json                   # TalkToFigma MCP конфиг
└── README.md
```

---

## 3. Backend API

### Базовый URL
- Локально: `http://localhost:8000`
- Префикс: `/api/v1`
- Авторизации нет (rate limit по IP).
- Формат ошибок: `{"detail": "...", "code": "ERROR_CODE"}`.

### Endpoints

| Метод | Путь | Описание | Коды |
|---|---|---|---|
| GET | `/api/v1/health` | Healthcheck | `200` |
| POST | `/api/v1/youtube/jobs` | Создать задачу извлечения | `202`, `422`, `429` |
| GET | `/api/v1/youtube/jobs/{job_id}` | Статус задачи | `200`, `404` |
| GET | `/api/v1/youtube/jobs/{job_id}/file` | Скачать готовый WAV | `200`, `404`, `409` |
| DELETE | `/api/v1/youtube/jobs/{job_id}` | Удалить задачу + файл | `204` |

### POST /youtube/jobs (rate limit 10/мин/IP)

Request:
```json
{ "url": "https://www.youtube.com/watch?v=...", "format": "wav" }
```
- `url` — обязателен, host из whitelist (`youtube.com`, `www.youtube.com`, `m.youtube.com`, `music.youtube.com`, `youtu.be`).
- `format` — поддерживается только `wav`.

Response 202:
```json
{ "job_id": "uuid-v4", "status": "pending" }
```
- `422`: `{"code":"VALIDATION_ERROR", ...}` — невалидный URL/host/format.
- `429`: `{"code":"RATE_LIMITED", ...}`.

### GET /youtube/jobs/{job_id} (rate limit 60/мин/IP)

Response 200:
```json
{
  "job_id": "...",
  "status": "pending|downloading|converting|completed|failed",
  "progress": 0-100,
  "title": "...",
  "thumbnail_url": "https://i.ytimg.com/...",
  "duration_sec": 119,
  "error_code": null,
  "error_message": null
}
```

Жизненный цикл: `pending → downloading → converting → completed` (или `→ failed`). Polling рекомендуется раз в 1.5–2 секунды.

`error_code` (когда `failed`):
- `BOT_DETECTED` — YouTube требует «не бот»; митигация — cookies/proxy через env.
- `GEO_BLOCKED` — недоступно в регионе.
- `EXTRACTION_FAILED` / `UNAVAILABLE` — другие ошибки yt-dlp.
- `CONVERSION_FAILED` — сбой ffmpeg.
- `TIMEOUT` — задача >5 мин.

### GET /youtube/jobs/{job_id}/file

Response 200: `audio/wav` (PCM 16-bit, 44.1 kHz, stereo), `Content-Disposition: attachment`, `X-Content-Type-Options: nosniff`.

`409`:
- `JOB_NOT_READY` — статус не `completed`.
- `JOB_FAILED` — задача завершилась ошибкой (`error_message` в ответе).

### DELETE /youtube/jobs/{job_id}

Response `204`. Удаляет запись из Redis + файл с диска.

### Локальная конвертация — на клиенте

Файлы из Gallery/Files **не загружаются** на сервер. Mobile конвертирует через `ffmpeg_kit_flutter_new`. API нужен только для YouTube-флоу.

---

## 4. Запуск

### Backend (Docker)

```bash
cp backend/.env.example backend/.env  # один раз
docker compose up -d --build
```

Сервисы:
- `api` — FastAPI на `http://localhost:8000`
- `redis` — на `:6379`
- `worker` — arq, забирает задачи из Redis

Healthcheck: `curl http://localhost:8000/api/v1/health` → `{"status":"ok","version":"0.1.0"}`.

OpenAPI Docs (только в dev): `http://localhost:8000/docs`.

### Backend (локально без Docker)

```bash
cd backend
python3.12 -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
# В одном терминале — API:
uvicorn app.main:app --reload
# В другом — worker (нужен Redis на :6379 + ffmpeg в PATH):
arq app.workers.arq_settings.WorkerSettings
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run -d <iphone-simulator-id>     # iPhone симулятор
flutter run -d <ipad-simulator-id>       # iPad
```

Базовый URL backend подбирается автоматически по платформе:
- iOS-симулятор → `http://127.0.0.1:8000`
- Android-эмулятор → `http://10.0.2.2:8000`
- Физическое устройство → `configureDependencies(apiBaseUrl: '<IP>')` в `mobile/lib/main.dart`.

---

## 5. Тесты и качество

### Backend

```bash
cd backend && source .venv/bin/activate
pytest -q                       # 42 теста, должны быть зелёные
pytest --cov=app --cov-report=term  # coverage ≥80%
ruff check app                  # lint
ruff format --check app         # format
mypy app --strict               # types (требует доустановки)
```

Стандартные критерии: тесты green, ruff/mypy clean, coverage ≥80%.

### Mobile

```bash
cd mobile
flutter analyze                 # 0 issues
flutter test                    # bloc/usecase/utility тесты
```

### Конфигурация (.env)

| Переменная | По умолчанию | Назначение |
|---|---|---|
| `APP_ENV` | `dev` | `dev` показывает /docs |
| `LOG_LEVEL` | `INFO` | structlog уровень |
| `REDIS_URL` | `redis://redis:6379/0` | broker arq + storage Job |
| `JOB_TTL_SEC` | `3600` | TTL записи job в Redis |
| `JOB_TIMEOUT_SEC` | `300` | таймаут extract_audio_task |
| `TMP_DIR` | `/tmp/mp3craft` | временные файлы |
| `RATE_LIMIT_CREATE` | `10/minute` | slowapi для POST /jobs |
| `RATE_LIMIT_STATUS` | `60/minute` | slowapi для GET /jobs/{id} |
| `ALLOWED_HOSTS_RAW` | список через запятую | whitelist для YouTube URL |
| `CORS_ORIGINS_RAW` | `*` | CORS origins (через запятую) |
| `YT_COOKIES_PATH` | пусто | путь к cookies.txt (обход bot-detection) |
| `YT_PROXY` | пусто | URL прокси (для cloud IP) |

**Важно:** в backend все list-настройки (`ALLOWED_HOSTS_RAW`, `CORS_ORIGINS_RAW`) — строки через запятую, **не JSON**. Парсинг — через `@property` в `app/core/config.py`. Это нужно из-за поведения pydantic-settings, который пытается JSON-декодировать `list[str]` из env.

---

## 6. Известные правила и подводные камни

1. **Не передавай `_job_timeout` в `enqueue_job(...)`.** Текущая версия arq пробрасывает kwarg в саму task-функцию → `TypeError`. Глобальный таймаут уже задан в `WorkerSettings.job_timeout = 300`.
2. **YouTube bot detection.** На cloud-IP yt-dlp может ловить «Sign in to confirm…». Митигация: `YT_COOKIES_PATH` + `YT_PROXY`. Для локального запуска обычно не требуется.
3. **Только WAV.** Backend и клиент валидируют `format: "wav"`. Если ТЗ изменится — добавлять формат в трёх местах: `app/schemas/youtube.py`, `app/services/audio_converter.py`, `mobile/.../ffmpeg_local_ds.dart`.
4. **iPad адаптация.** В mobile все размеры через `app/theme/app_dimens.dart` + `core/utils/platform_utils.dart` (breakpoint 600px). В виджетах — никаких magic numbers.
5. **Дизайн-токены — в `mobile/lib/app/theme/`.** Цвета, шрифты, отступы, радиусы. См. `docs/design-tokens.md` для соответствия Figma.

---

## 7. Workflow / коммиты

- Ветка фичи: `feat/<kebab>` от `main`.
- Сообщения коммитов **на русском** в формате `type(scope): описание`.
- Scope: `api` / `service` / `repo` / `model` / `db` / `auth` / `devops` / `core` / `ui`.
- НЕ коммитить: `.env`, `__pycache__/`, `.pytest_cache/`, `.mypy_cache/`, `htmlcov/`, `.coverage`, `*.db`, `*.sqlite3`.

---

## 8. MCP

`.mcp.json` в корне настраивает **Talk To Figma** (cursor-talk-to-figma-mcp). Используется для извлечения дизайн-токенов и ассетов прямо из Figma. После изменения `.mcp.json` нужен рестарт Claude Code.

Подключение к каналу плагина в Figma: `mcp__TalkToFigma__join_channel(channel="<channel-id>")`. Канал берётся из плагина «Talk To Figma» в Figma.

---

## 9. Ссылки

- План: [`docs/plans/image-1-image-2-linear-swing.md`](docs/plans/image-1-image-2-linear-swing.md)
- API-контракт: [`docs/api-contract.md`](docs/api-contract.md)
- Backend README: [`backend/README.md`](backend/README.md)
- Mobile README: [`mobile/README.md`](mobile/README.md)
