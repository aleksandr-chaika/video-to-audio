# MP3 Craft — план разработки

## 1. Контекст

**Задача.** Реализовать тестовое приложение «MP3 Craft»: Flutter (iOS/iPad) + FastAPI backend.

**Функциональность.**
- Конвертация локальных MP3/MP4 → WAV (на устройстве, ffmpeg_kit_flutter).
- Извлечение аудио из YouTube → WAV (на сервере через yt-dlp + ffmpeg).
- Превью результата (плеер, обложка/иконка), Crop Audio (обрезка диапазона), Share, локальная история.

**Стек (зафиксирован пользователем).**
- Backend: FastAPI.
- Mobile: Flutter, обязательные библиотеки — `get_it`, `injectable`, `flutter_bloc`, `sqflite`. Адаптация iPhone/iPad.
- Локальная конвертация — на клиенте; YouTube extraction — на сервере; режим — async (job_id + polling); монорепо `backend/ + mobile/`; auth нет, rate limit по IP.

**Оценивается:** архитектура, обработка ошибок, состояния, пиксель-перфект, KISS/DRY/SOLID.

## 2. Структура монорепо

```
video-to-audio-convert/
├── backend/                    # FastAPI
├── mobile/                     # Flutter
├── docs/
│   ├── plans/                  # планы (этот файл)
│   └── api-contract.md         # OpenAPI-спека (поддерживается синхронно с кодом)
├── docker-compose.yml          # api + redis + worker (для локальной разработки backend)
└── README.md
```

## 3. Backend (FastAPI)

### 3.1. Выбор библиотек (исследование)

| Библиотека | Решение | Обоснование |
|---|---|---|
| **yt-dlp** | ✓ берём | Самый популярный, активно поддерживается, переживает breaking changes YouTube. Альтернативы (`pytube` — мёртв, `pytubefix` — нишевый) уступают по reliability. |
| **ffmpeg** (system binary) | ✓ нужен | Постпроцессор yt-dlp + конвертация в WAV. Ставится в Docker-образ. |
| **arq** (Redis-based job queue) | ✓ берём | Async-native, легче Celery, работает поверх Redis, идеально для FastAPI. |
| **slowapi** | ✓ берём | Rate limit по IP для FastAPI (decorator-based). |
| **redis** (storage + queue) | ✓ берём | Хранит job state + используется arq как broker. |
| pydantic v2, sqlalchemy 2.0 | — | sqlalchemy НЕ нужен (нет реляционной БД, состояние jobs в Redis). |

**Замечание про production yt-dlp.** На cloud-IP YouTube часто триггерит «Sign in to confirm you're not a bot». Митигации заложены в архитектуру:
- Поддержка `cookies.txt` через переменную окружения `YT_COOKIES_PATH` (опционально).
- Поддержка `proxy` через `YT_PROXY` (опционально).
- Обработка ошибок yt-dlp (`DownloadError`, `ExtractorError`) → корректный 503/422.

### 3.2. Структура backend

```
backend/
├── app/
│   ├── main.py                       # FastAPI app + lifespan + middlewares
│   ├── core/
│   │   ├── config.py                 # Settings (pydantic-settings, .env)
│   │   ├── logging.py                # structured logging (structlog)
│   │   ├── errors.py                 # AppError, exception_handlers
│   │   └── rate_limit.py             # slowapi limiter
│   ├── api/
│   │   └── v1/
│   │       ├── deps.py               # Depends() (limiter, services)
│   │       └── endpoints/
│   │           ├── youtube.py        # POST/GET endpoints
│   │           └── health.py         # GET /health
│   ├── schemas/
│   │   ├── youtube.py                # JobCreateRequest/Response, JobStatus
│   │   └── common.py                 # ErrorResponse
│   ├── services/
│   │   ├── youtube_service.py        # бизнес-логика: создать job, статус, отдать файл
│   │   └── audio_converter.py        # обёртка над ffmpeg (subprocess.exec с asyncio)
│   ├── integrations/
│   │   └── ytdlp_client.py           # async-обёртка yt-dlp (через executor)
│   ├── repositories/
│   │   └── job_repository.py         # хранение состояния job в Redis (TTL)
│   ├── workers/
│   │   ├── arq_settings.py           # WorkerSettings для arq
│   │   └── tasks.py                  # async def extract_audio_task(ctx, job_id, url)
│   └── domain/
│       └── job.py                    # dataclass Job (status, progress, file_path, error)
├── tests/
│   ├── conftest.py                   # httpx.AsyncClient, fakeredis fixtures
│   ├── integration/
│   │   ├── test_youtube_endpoints.py # реальные HTTP-вызовы (httpx.AsyncClient)
│   │   └── test_health.py
│   └── unit/
│       ├── test_youtube_service.py
│       ├── test_audio_converter.py   # с моком subprocess
│       └── test_ytdlp_client.py      # с respx/моком
├── alembic/                          # НЕ нужен (Redis-only)
├── pyproject.toml
├── Dockerfile                        # multistage (python:3.12-slim)
├── .env.example
└── README.md
```

### 3.3. API-контракт (v1)

Все эндпоинты префиксуются `/api/v1`. Базовый response envelope не нужен — стандартный JSON. Ошибки в формате `{"detail": "...", "code": "ERROR_CODE"}`.

**POST `/api/v1/youtube/jobs`** — создать job на извлечение аудио.
- Request: `{"url": "https://youtube.com/watch?v=...", "format": "wav"}`
- 202 Accepted: `{"job_id": "uuid", "status": "pending"}`
- 422: некорректный URL (валидация Pydantic + проверка `YoutubeURL` regex/host).
- 429: превышен rate limit.

**GET `/api/v1/youtube/jobs/{job_id}`** — статус job.
- 200: `{"job_id": "...", "status": "pending|downloading|converting|completed|failed", "progress": 0..100, "title": "...", "thumbnail_url": "...", "duration_sec": 374, "error_code": null}`
- 404: job не существует / истёк TTL.

**GET `/api/v1/youtube/jobs/{job_id}/file`** — скачать готовый WAV.
- 200: `audio/wav` (StreamingResponse).
- 404: файл не готов / не существует.
- 409: job в статусе `failed` или ещё не `completed`.

**DELETE `/api/v1/youtube/jobs/{job_id}`** — удалить job + файл (явный cleanup).
- 204.

**GET `/api/v1/health`** — `{"status": "ok"}` (для k8s/docker healthcheck).

### 3.4. Жизненный цикл job

```
[Client] POST /youtube/jobs ──► [API] валидирует URL ──► [JobRepository] сохраняет Job(status=pending) в Redis (TTL=1h)
                                                    └──► [arq] enqueue extract_audio_task(job_id, url)
                                                    └──► 202 {job_id, status:pending}

[Worker] extract_audio_task:
  1. status=downloading; yt-dlp скачивает best audio в /tmp/{job_id}/source
  2. status=converting;  ffmpeg → /tmp/{job_id}/output.wav
  3. status=completed;   сохраняем title/thumbnail/duration/file_path
  Ошибки → status=failed, error_code (UNAVAILABLE / GEO_BLOCKED / BOT_DETECTED / EXTRACTION_FAILED / CONVERSION_FAILED).

[Client] GET /youtube/jobs/{id} (polling каждые 1.5–2с)
[Client] когда status=completed → GET /youtube/jobs/{id}/file → StreamingResponse(wav)
[Cleanup] фоновая задача (arq cron) каждые 10 мин: чистит файлы старше 1 часа.
```

### 3.5. Rate limit и безопасность

- `slowapi`: 10 запросов/мин на IP для `POST /youtube/jobs`, 60/мин для `GET /jobs/{id}`.
- Валидация URL: только `youtube.com`, `youtu.be`, `m.youtube.com` (whitelist хостов).
- Никаких секретов в коде; всё через `.env`.
- CORS: разрешить только нужные origin'ы (`mobile` использует HTTP клиент, не браузер — но для веб-прототипов оставим `*` в dev и whitelist в prod).
- Файлы в `/tmp/jobs/{uuid}` (UUIDv4 — не угадать) + `X-Content-Type-Options: nosniff`.

### 3.6. Конфигурация (.env.example)

```
APP_ENV=dev
LOG_LEVEL=INFO
REDIS_URL=redis://redis:6379/0
JOB_TTL_SEC=3600
TMP_DIR=/tmp/mp3craft
RATE_LIMIT_CREATE=10/minute
RATE_LIMIT_STATUS=60/minute
YT_COOKIES_PATH=                 # опционально
YT_PROXY=                        # опционально
ALLOWED_HOSTS=youtube.com,youtu.be,m.youtube.com,www.youtube.com
```

### 3.7. Docker

**`backend/Dockerfile`** (multistage):
- `builder`: `python:3.12-slim` + `pip install` в virtualenv.
- `runtime`: `python:3.12-slim` + `apt-get install ffmpeg` + копия venv. Запуск: `gunicorn -k uvicorn.workers.UvicornWorker app.main:app`.

**`docker-compose.yml`** (корневой):
- `api`: backend container.
- `redis`: redis:7-alpine.
- `worker`: тот же образ, `command: arq app.workers.arq_settings.WorkerSettings`.

## 4. Mobile (Flutter)

### 4.1. Выбор библиотек

| Назначение | Пакет |
|---|---|
| State | `flutter_bloc` |
| DI | `get_it` + `injectable` (+ `injectable_generator`) |
| Local DB (history) | `sqflite` + `sqflite_common_ffi` (для тестов) |
| Models | `freezed` + `json_serializable` |
| Functional types | `dartz` (Either) — для чистой обработки ошибок в domain |
| Routing | `go_router` |
| HTTP | `dio` + `dio_http_formatter` (logging) |
| Audio playback | `just_audio` |
| Waveform (preview + crop) | `audio_waveforms` |
| Local convert MP3/MP4 → WAV | `ffmpeg_kit_flutter_audio` |
| Crop / trim audio | `ffmpeg_kit_flutter_audio` (через `-ss`/`-to`) |
| File picker | `file_picker` |
| Gallery picker | `image_picker` (для видео) или `photo_manager` (если нужна обложка) |
| Share | `share_plus` |
| Paths / storage | `path_provider`, `path` |
| URL paste | `flutter/services` (Clipboard API) |
| Permissions | `permission_handler` |
| Адаптация iPad | `flutter_screenutil` или нативный `LayoutBuilder` + breakpoints |

### 4.2. Архитектура — Clean Architecture (feature-first)

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart                  # MaterialApp.router + theme
│   │   ├── di/
│   │   │   ├── injection.dart        # GetIt + @InjectableInit
│   │   │   └── injection.config.dart # сгенерированный
│   │   ├── router/
│   │   │   └── app_router.dart       # go_router routes
│   │   └── theme/
│   │       ├── app_colors.dart       # из мокапов: тёмный фон, синий accent, gradient
│   │       ├── app_text_styles.dart  # SF Pro: title, body, caption
│   │       ├── app_dimens.dart       # отступы 8/12/16/20/24, radii 12/16/24
│   │       └── app_theme.dart
│   ├── core/
│   │   ├── error/
│   │   │   ├── failures.dart         # Failure (sealed) — Network/Server/Validation/Cancelled/Unknown
│   │   │   └── exceptions.dart       # ApiException, ConversionException
│   │   ├── network/
│   │   │   ├── dio_client.dart       # @lazySingleton, interceptors (logging, retry)
│   │   │   └── api_endpoints.dart
│   │   ├── usecase/
│   │   │   └── usecase.dart          # abstract UseCase<T, P>
│   │   ├── utils/
│   │   │   ├── duration_formatter.dart   # 06:34 / 01:03:23
│   │   │   ├── file_utils.dart           # detect mime, size
│   │   │   ├── url_validator.dart        # YouTube URL regex
│   │   │   └── platform_utils.dart       # isPad, breakpoints
│   │   └── widgets/                       # переиспользуемые presentational
│   │       ├── primary_button.dart        # blue gradient (Share/Save)
│   │       ├── icon_card_button.dart      # синяя «карточка» (Gallery/Files/YouTube)
│   │       ├── url_input_field.dart       # поле YouTube с paste/clear/check
│   │       ├── format_badge.dart          # MP3/MP4/WAV badge
│   │       └── loading_overlay.dart       # «Processing…» (модал из Image#2)
│   ├── features/
│   │   ├── home/
│   │   │   ├── data/                       # (нет — фича чисто UI)
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── bloc/home_bloc.dart     # выбор источника
│   │   │       └── pages/home_page.dart
│   │   ├── convert/                        # локальная конвертация MP3/MP4 → WAV
│   │   │   ├── domain/
│   │   │   │   ├── entities/audio_source.dart
│   │   │   │   ├── repositories/converter_repository.dart   # abstract
│   │   │   │   └── usecases/convert_local_file.dart
│   │   │   ├── data/
│   │   │   │   ├── datasources/ffmpeg_local_ds.dart         # ffmpeg_kit_flutter_audio
│   │   │   │   └── repositories/converter_repository_impl.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/convert_bloc.dart  # idle/picking/processing/done/error
│   │   │       └── pages/processing_page.dart   # модал «Processing…»
│   │   ├── youtube/                        # backend extraction
│   │   │   ├── domain/
│   │   │   │   ├── entities/yt_job.dart    # JobStatus enum + поля
│   │   │   │   ├── repositories/yt_repository.dart
│   │   │   │   └── usecases/{create_yt_job,poll_yt_job,download_yt_file}.dart
│   │   │   ├── data/
│   │   │   │   ├── datasources/yt_remote_ds.dart            # dio
│   │   │   │   ├── models/yt_job_model.dart                 # freezed + json
│   │   │   │   └── repositories/yt_repository_impl.dart
│   │   │   └── presentation/
│   │   │       └── bloc/youtube_bloc.dart  # creating/polling(progress)/downloading/done/error
│   │   ├── result/                         # экран Result (Image#3)
│   │   │   └── presentation/
│   │   │       ├── bloc/result_bloc.dart   # play/pause/seek/share/delete
│   │   │       └── pages/result_page.dart
│   │   ├── crop/                           # экран Crop Audio (Image#4)
│   │   │   ├── domain/
│   │   │   │   └── usecases/crop_audio.dart
│   │   │   ├── data/
│   │   │   │   └── datasources/ffmpeg_crop_ds.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/crop_bloc.dart     # range start/end + scrub
│   │   │       └── pages/crop_page.dart
│   │   ├── history/                        # sqflite
│   │   │   ├── domain/
│   │   │   │   ├── entities/history_item.dart
│   │   │   │   ├── repositories/history_repository.dart
│   │   │   │   └── usecases/{add_history,get_history,delete_history_item}.dart
│   │   │   ├── data/
│   │   │   │   ├── datasources/history_local_ds.dart        # sqflite
│   │   │   │   ├── models/history_item_model.dart
│   │   │   │   └── repositories/history_repository_impl.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/history_bloc.dart  # loading/empty/loaded
│   │   │       └── widgets/{history_grid.dart,history_empty.dart,history_card.dart}
│   │   └── settings/
│   │       └── presentation/pages/settings_page.dart
│   └── l10n/                                # ARB-файлы (en — обязателен; ru — опционально)
├── test/
│   ├── unit/                                # bloc tests, usecase tests, repository tests (моки)
│   ├── widget/                              # widget tests
│   └── integration/                         # tests для sqflite (sqflite_common_ffi)
├── pubspec.yaml
├── build.yaml                               # injectable_generator config
├── analysis_options.yaml                    # very_good_analysis или flutter_lints
└── README.md
```

### 4.3. Главные блоки состояний (BLoC)

Все блоки используют **sealed states + sealed events** (через freezed) — компилятор не даст забыть кейс.

- `HomeBloc`: idle (отображение grid + history) → переход на `convert/youtube/result`.
- `ConvertBloc`: `Idle → Picking → Processing(progress?) → Done(filePath) | Error(failure)`.
- `YoutubeBloc`: `Idle → Validating → CreatingJob → Polling(jobId, status, progress) → Downloading(progress) → Done(filePath, meta) | Error`.
- `ResultBloc`: `Loading → Ready(playerState, position, duration) → ShareInProgress → Deleted`.
- `CropBloc`: `Loaded(waveform, total, range) → Saving → Saved | Error`.
- `HistoryBloc`: `Loading → Empty | Loaded(items) → ItemDeleted`.

### 4.4. Маршруты (go_router)

```
/                               # Home
/processing                     # модалка (showDialog) или роут с opaque=false
/result?path=...&meta=...
/crop?path=...
/settings
```

### 4.5. Дизайн-система (для пиксель-перфекта)

Извлечено из мокапов (Image #1–#4):

| Токен | Значение |
|---|---|
| `bg.primary` | очень тёмный (≈ `#000814`/`#0A0E1A`) |
| `bg.surface` | карточка из мокапа: глубокий синий gradient (`#0E1A33` → `#1B2D5A`) |
| `accent.primary` | bright blue (`#3B82F6` / `#2F6BFF`) |
| `accent.gradient` | от светло-голубого к синему (Gallery/Files/Save кнопки) |
| `text.primary` | white |
| `text.secondary` | `#8E97A6` |
| `danger` | red (`#FF3B30`) — иконка корзины на Result |
| Radii | 12 (бэйджи), 16 (поля), 24 (большие карточки) |
| Шрифт | SF Pro Display (system) — Title 28/Bold, Subtitle 17/Regular, Caption 13 |
| Иконки | SF Symbols-style (Cupertino) + custom для логотипа (камера + микрофон) |

**Адаптация iPhone/iPad:**
- Breakpoint: ширина ≥ 600 — двухколонник (карточки в ряд × 2 → × 4; история grid 4 столбца вместо 2).
- `LayoutBuilder` в каждом page; общий `ResponsiveBuilder` widget в `core/widgets/`.
- Все размеры через `app_dimens.dart` (нет magic numbers в виджетах).

### 4.6. Обработка ошибок (Flutter)

- Domain возвращает `Either<Failure, T>` (dartz).
- BLoC мапит Failure → user-friendly сообщение (через l10n keys).
- Сетевые ошибки: ретрай в dio interceptor (3 попытки с экспонентой) → если всё равно fail → `NetworkFailure`.
- YouTube-specific: `BotDetectionFailure` (показать «попробуйте позже»), `UnavailableFailure`, `GeoBlockedFailure`.
- ffmpeg ошибки: `ConversionFailure(stderr)` → лог + generic message пользователю.

### 4.7. Локальная история (sqflite)

Таблица `history` (одна, без миграций для MVP):
```sql
CREATE TABLE history (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  source_type TEXT NOT NULL CHECK (source_type IN ('local','youtube')),
  source_format TEXT NOT NULL,           -- 'mp3' | 'mp4'
  output_format TEXT NOT NULL,           -- 'wav'
  file_path   TEXT NOT NULL,             -- абсолютный путь в app docs
  title       TEXT,
  duration_ms INTEGER NOT NULL,
  thumbnail_path TEXT,
  created_at  INTEGER NOT NULL           -- unix ms
);
CREATE INDEX idx_history_created_at ON history(created_at DESC);
```

Item удалён из истории → удаляется и файл (через usecase, чтобы не копить мусор).

## 5. Соответствие экранов мокапам

| Мокап | Экран | Ключевые виджеты |
|---|---|---|
| Image #1 (Main) | `HomePage` | Header (settings + logo «Craft» + 3D-иконка), 2 IconCardButton (Gallery/Files), `UrlInputField` с YouTube-логотипом, секция History (grid 2 колонки на iPhone). |
| Image #1 (empty history) | `HistoryEmpty` | Иконка микрофона/волны, текст «Your History Is Empty». |
| Image #2 (Process Loading) | `ProcessingPage`/Dialog | Полноэкранный затемнённый overlay, центральный квадрат + «Processing…», подпись «Please stay on this screen…». |
| Image #3 (Result) | `ResultPage` | AppBar (close × + «Result» + красная корзина), большой preview-блок с waveform + иконкой/обложкой/кадром видео, формат-бейджи (`MP3 → WAV`), длительность, `CropAudio` button (outline), плеер (play/pause + slider + 00:45 / -2:38), `Share` primary button. |
| Image #4 (Crop Audio) | `CropPage` | Тот же preview + waveform-trimmer (две ручки + текущий диапазон 03:56 – 13:03 / 16:23) + кнопка `Save` (полная ширина). |

## 6. План реализации (фазы и ответственные агенты)

> Соответствует workflow оркестратора (`.claude/skills/orchestrator/SKILL.md`).

### Фаза A — Backend MVP

| # | Задача | Агент | Файлы |
|---|---|---|---|
| A1 | Скелет FastAPI + конфиг + Dockerfile + docker-compose | devops-agent + python-dev | `backend/app/main.py`, `core/config.py`, `Dockerfile`, `docker-compose.yml` |
| A2 | Schemas + endpoints `/youtube/jobs` (заглушки) + `/health` | python-dev | `app/api/v1/endpoints/*`, `app/schemas/*` |
| A3 | Job repository (Redis) + Job domain | python-dev | `app/repositories/job_repository.py`, `app/domain/job.py` |
| A4 | yt-dlp интеграция + audio_converter (ffmpeg) | python-dev | `app/integrations/ytdlp_client.py`, `app/services/audio_converter.py` |
| A5 | arq worker + extract_audio_task + cleanup cron | python-dev | `app/workers/*` |
| A6 | Связка endpoints → service → repo + cтатусы/файл | python-dev | `app/services/youtube_service.py` |
| A7 | Rate limit (slowapi) + exception handlers | python-dev | `app/core/rate_limit.py`, `app/core/errors.py` |
| A8 | Тесты: unit (service, ytdlp client с моком) + integration (httpx + fakeredis) | python-tester | `backend/tests/**` |
| A9 | Review + gate (mypy strict, ruff, pytest, pip-audit) | python-reviewer | — |

### Фаза B — Mobile core

| # | Задача | Файлы |
|---|---|---|
| B1 | Flutter проект + pubspec + analysis_options + injection skeleton | `mobile/`, `pubspec.yaml`, `lib/app/di/*` |
| B2 | Theme + design tokens (app_colors/text/dimens) + core widgets (PrimaryButton, IconCardButton, UrlInputField, FormatBadge, LoadingOverlay) | `lib/app/theme/*`, `lib/core/widgets/*` |
| B3 | Routing + go_router + main.dart | `lib/app/app.dart`, `lib/app/router/*` |
| B4 | DioClient + ApiEndpoints + interceptors (retry, logging) | `lib/core/network/*` |
| B5 | sqflite + history feature (data/domain/presentation) | `lib/features/history/**` |

### Фаза C — Mobile features

| # | Задача | Файлы |
|---|---|---|
| C1 | Home page (pixel-perfect Image#1) + HomeBloc | `lib/features/home/**` |
| C2 | Convert feature (ffmpeg_kit_flutter_audio) + ProcessingPage | `lib/features/convert/**` |
| C3 | YouTube feature (dio client → polling → download) + url validator | `lib/features/youtube/**` |
| C4 | Result page (pixel-perfect Image#3) + just_audio + audio_waveforms | `lib/features/result/**` |
| C5 | Crop feature (Image#4): waveform trimmer + ffmpeg `-ss/-to` + Save | `lib/features/crop/**` |
| C6 | Share через share_plus + delete + cleanup | — |

### Фаза D — Качество

- Unit-тесты блоков (через `bloc_test`) + usecases.
- Widget-тесты ключевых страниц.
- Integration-тест sqflite (sqflite_common_ffi).
- Адаптация iPad (LayoutBuilder breakpoints).
- Pixel-perfect ревью с дизайном (попиксельное сравнение через Figma/мокапы).

### Фаза E — Сборка и документация

- `docs/api-contract.md` — финальный OpenAPI snapshot.
- `README.md` корня + backend/README.md + mobile/README.md (как запустить).
- `.env.example` обоих проектов.

## 7. Файлы, которые будут созданы (опорный список)

**Backend (≈25 файлов кода + ≈12 тестов):** см. дерево в §3.2.

**Mobile (≈60 файлов кода + ≈25 тестов):** см. дерево в §4.2.

## 8. Переиспользуемые паттерны (что точно не дублировать)

- **PrimaryButton** — единственный синий gradient-кнопочный виджет (Share/Save/Submit).
- **IconCardButton** — Gallery/Files/YouTube/любая будущая карточка-источник.
- **FormatBadge** — `MP3`, `MP4`, `WAV` бейджи во всех экранах.
- **DurationFormatter** — единая функция `formatDuration(Duration)` → `06:34` / `01:03:23` / `-2:38`.
- **AudioPreviewBlock** — большая «обложка» (иконка/Image/видео-кадр) — общий между Result и Crop.

## 9. Верификация (как проверять)

### Backend
- `cd backend && docker compose up --build` — поднимаются api+redis+worker.
- `curl -X POST localhost:8000/api/v1/youtube/jobs -d '{"url":"<реальное короткое видео>"}'` → 202 + job_id.
- `curl localhost:8000/api/v1/youtube/jobs/<id>` (повторно) → status переходит pending → downloading → converting → completed.
- `curl localhost:8000/api/v1/youtube/jobs/<id>/file -o out.wav` → файл играется.
- Rate limit: 11 быстрых POST → 11-й вернёт 429.
- `pytest -x --cov=app --cov-fail-under=80` зелёный.
- `mypy app --strict` и `ruff check app` чистые.

### Mobile
- `flutter pub get && dart run build_runner build` — генерация без ошибок.
- `flutter run -d <iphone>` — запускается, экраны соответствуют мокапам.
- iPad-симулятор: layout перестраивается (карточки в ряд, history в 4 колонки).
- Локальная конвертация: выбрать MP4 → процессинг → Result → файл проигрывается.
- YouTube: вставить ссылку → check → процессинг → Result.
- Crop: выбрать диапазон → Save → новый файл сохранён, играется именно вырезанный фрагмент.
- Share: запускается системный share-sheet с WAV.
- История: после конвертации появляется запись; после удаления — пропадает; файл удаляется с диска.
- `flutter test` зелёный (unit + widget + integration).
- `flutter analyze` чистый.

## 10. Открытые риски (явно обозначены)

1. **YouTube bot detection на cloud.** На production-IP yt-dlp может ловить «Sign in to confirm…». Митигация: cookies/proxy через env. Для тест-задания — запускать локально / на резидентном IP.
2. **Размер ffmpeg в iOS-сборке.** `ffmpeg_kit_flutter_audio` — наименьший пакет (≈30 MB), достаточный для MP3/MP4/WAV. Полный `ffmpeg_kit_flutter` (~150 MB) не нужен.
3. **Длинные YouTube-видео.** Job timeout = 5 мин. Видео >5 мин загрузки могут не уложиться — обрабатывается как `EXTRACTION_FAILED` с понятным сообщением.
4. **iPad адаптация — это работа, не «бесплатное».** Заложено в Фазу C/D как явная задача.

## 11. Что НЕ входит в MVP (явно)

- Серверная история / синхронизация между устройствами.
- Авторизация (JWT/OAuth).
- Push-уведомления о готовности job.
- Поддержка форматов кроме WAV на выходе (FLAC/OGG — на будущее).
- Веб-версия / Android (только iOS/iPad согласно ТЗ).
- CI (GitHub Actions) — оставлено за скоупом MVP, README покроет ручной запуск.
