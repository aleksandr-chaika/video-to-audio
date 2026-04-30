# MP3 Craft — API Contract

**Base URL.** `http://<host>:8000/api/v1`

**Авторизация.** Нет (rate limit по IP через `slowapi`).

**Формат ошибок.** `application/json`:
```json
{
  "detail": "Сообщение для пользователя",
  "code": "ERROR_CODE"
}
```

## Эндпоинты

### `POST /youtube/jobs`

Создать задачу извлечения аудио из YouTube.

**Rate limit:** 10/min/IP.

**Request body:**
```json
{
  "url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
  "format": "wav"
}
```

Поля:
- `url` (string, required) — должен быть на одном из whitelisted-хостов (`youtube.com`, `www.youtube.com`, `m.youtube.com`, `music.youtube.com`, `youtu.be`).
- `format` (string, default `"wav"`) — поддерживается только `"wav"`.

**Responses:**
- `202 Accepted`:
  ```json
  {
    "job_id": "f5e3...",
    "status": "pending"
  }
  ```
- `422`: `{"code": "VALIDATION_ERROR", "detail": "..."}` — невалидный URL/host/format.
- `429`: `{"code": "RATE_LIMITED", "detail": "..."}`.

---

### `GET /youtube/jobs/{job_id}`

Запросить статус задачи. Полить каждые 1.5–2 секунды до `completed` или `failed`.

**Rate limit:** 60/min/IP.

**Response 200:**
```json
{
  "job_id": "f5e3...",
  "status": "downloading",
  "progress": 35,
  "title": "Some Track",
  "thumbnail_url": "https://i.ytimg.com/...",
  "duration_sec": 374,
  "error_code": null,
  "error_message": null
}
```

`status` ∈ {`pending`, `downloading`, `converting`, `completed`, `failed`}.

`error_code` (когда `status == "failed"`):
- `BOT_DETECTED` — YouTube требует подтверждения «не бот».
- `GEO_BLOCKED` — недоступно в регионе.
- `UNAVAILABLE` / `EXTRACTION_FAILED` — другая ошибка yt-dlp.
- `CONVERSION_FAILED` — сбой ffmpeg.
- `TIMEOUT` — превышен лимит обработки (5 мин).

**Response 404:** `{"code": "JOB_NOT_FOUND"}` — нет такой задачи (или истёк TTL = 1 час).

---

### `GET /youtube/jobs/{job_id}/file`

Скачать готовый WAV.

**Response 200:** `audio/wav`, `Content-Disposition: attachment; filename="<job_id>.wav"`, `X-Content-Type-Options: nosniff`. Тело — бинарный PCM WAV (16-bit, 44.1 kHz, stereo).

**Response 404:** `JOB_NOT_FOUND` — задача не существует или файл удалён.

**Response 409:**
- `JOB_NOT_READY` — задача ещё не `completed`.
- `JOB_FAILED` — задача провалилась.

---

### `DELETE /youtube/jobs/{job_id}`

Удалить запись задачи и файл с диска.

**Response 204** — без тела.

---

### `GET /health`

```json
{
  "status": "ok",
  "version": "0.1.0"
}
```

## Жизненный цикл задачи

```
POST /jobs ─► 202 (pending)
                │
                ▼
           [arq worker]
                │
            downloading (yt-dlp)
                │
            converting (ffmpeg)
                │
                ▼
            completed
                │
GET /jobs/{id}/file ─► 200 audio/wav
```

При сбое: `status = "failed"`, заполнены `error_code` и `error_message`.

## Конвертация на клиенте

Локальные файлы (Gallery/Files) **не загружаются** на сервер. Mobile конвертирует их через `ffmpeg_kit_flutter_new`. API нужен только для YouTube-флоу.
