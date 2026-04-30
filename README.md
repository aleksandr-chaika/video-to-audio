# MP3 Craft

Flutter (iOS/iPad) + FastAPI приложение для конвертации аудио/видео в WAV и извлечения аудио из YouTube.

## Структура монорепо

```
.
├── backend/        # FastAPI + yt-dlp + arq (Redis)
├── mobile/         # Flutter (Clean Architecture, BLoC + GetIt + sqflite)
├── docs/
│   ├── plans/      # план разработки (image-1-image-2-linear-swing.md)
│   └── api-contract.md
├── docker-compose.yml
└── README.md
```

## Быстрый старт

### 1. Backend

```bash
cp backend/.env.example backend/.env
docker compose up --build
```

После старта:
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- Health: http://localhost:8000/api/v1/health

### 2. Mobile

```bash
cd mobile
flutter pub get
flutter run -d <iphone-simulator-id>
```

## Функциональность

- **Локальная конвертация MP3/MP4 → WAV** на устройстве через `ffmpeg_kit_flutter_new` (без аплоадов на сервер).
- **YouTube → WAV** через backend: `yt-dlp` качает best-audio + `ffmpeg` конвертирует в PCM WAV.
- **Превью**: just_audio + waveform.
- **Crop Audio** — обрезка диапазона (ffmpeg `-ss/-to`).
- **Share** — системный share-sheet.
- **Локальная история** в SQLite (sqflite); удаление вычищает файл с диска.

## Архитектура (high-level)

**Backend.** FastAPI + arq worker + Redis (state + queue). Async-режим: `POST /jobs → 202 + job_id`, polling `GET /jobs/{id}` каждые ~1.5 с, `GET /jobs/{id}/file` для WAV. Cleanup-cron каждые 10 мин.

**Mobile.** Clean Architecture (presentation → domain → data) per-feature. State — `flutter_bloc` (sealed states/events). DI — `get_it` (ручная регистрация в `app/di/injection.dart`). Routing — `go_router`. Все размеры/цвета/типографика — через `app/theme/*`.

Подробности и обоснование выбора библиотек: [`docs/plans/image-1-image-2-linear-swing.md`](docs/plans/image-1-image-2-linear-swing.md).

## Качество

| Часть | Метрика | Значение |
|---|---|---|
| Backend | pytest | 42 теста, 100% green |
| Backend | coverage | 87% (gate ≥80%) |
| Backend | ruff | clean |
| Backend | docker-compose | api + redis + worker |
| Mobile | flutter analyze | 0 issues |
| Mobile | flutter test | 24 теста, 100% green |

## Документация

- [План разработки](docs/plans/image-1-image-2-linear-swing.md)
- [API-контракт](docs/api-contract.md)
- [Backend README](backend/README.md)
- [Mobile README](mobile/README.md)
