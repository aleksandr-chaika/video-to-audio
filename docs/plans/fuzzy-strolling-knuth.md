# План: аудит и исправления code style / архитектуры

## Context

Запрошен полный аудит проекта **MP3 Craft** (FastAPI backend + Flutter mobile) и план исправлений критичных проблем. Аудит был проведён двумя параллельными Explore-агентами по каждой кодовой базе. Все найденные claim'ы дополнительно перепроверены чтением кода — несколько false-positive отфильтровано (см. секцию **Исключено из плана**).

Цель плана — исправить **критичные** и **высокоприоритетные** проблемы безопасности, корректности и архитектуры. Косметика и далёкий рефактор остаются за рамками — сделаем отдельной задачей при необходимости.

---

## Сводка находок

| Категория | Backend | Flutter |
|---|---|---|
| CRITICAL | 1 | 1 |
| HIGH | 4 | 3 |
| MEDIUM | 3 | 4 |
| Положительное | Clean Architecture, Pydantic v2, async везде корректно | Clean Architecture, Either/dartz, MethodChannel error handling |

---

## BACKEND — реальные проблемы

### 🔴 BE-1 [CRITICAL] Path traversal / отсутствие валидации границ tmp_dir
**Файл:** `backend/app/services/youtube_service.py:53-62`
**Проблема:** `path = Path(job.file_path)` — `file_path` записывается worker'ом в Redis, читается endpoint'ом для отдачи файла. Если Redis скомпрометирован или worker запишет относительный/симлинк-путь, FileResponse отдаст произвольный файл сервера.
**Фикс (defence-in-depth):**
```python
tmp_root = self._tmp_dir.resolve()
path = Path(job.file_path).resolve()
if not path.is_relative_to(tmp_root):
    raise JobNotFoundError(message="Файл вне разрешённой директории")
```
Аналогичная защита нужна и в `delete_job()` (там `shutil.rmtree(self._tmp_dir / job_id)` — `job_id` из URL без валидации UUID-формата → теоретический traversal через `..`).

### 🟠 BE-2 [HIGH] `except Exception` в worker глотает CancelledError/SystemExit
**Файл:** `backend/app/workers/tasks.py` (~line 60)
**Проблема:** Голый `except Exception as exc:` ловит и `asyncio.CancelledError` (в Py 3.8+ она — `BaseException`, ОК — но всё равно широкая ловля без re-raise мешает graceful shutdown воркера и скрывает баги).
**Фикс:** Ловить конкретные доменные исключения (`ConversionError`, `YouTubeUnavailableError`, `BotDetectedError`, `TimeoutError`) и логировать `Exception` отдельно с `logger.exception(...)` + re-raise.

### 🟠 BE-3 [HIGH] Job-десериализация из Redis без валидации схемы
**Файл:** `backend/app/repositories/job_repository.py:35-41`
**Проблема:** `Job.from_dict(json.loads(raw))` падает с `KeyError` при schema-drift / повреждении данных. Пользователь увидит 500 вместо понятной ошибки.
**Фикс:** Перевести `Job` на Pydantic-модель ИЛИ обернуть `from_dict` в try/except (`KeyError`, `ValueError`, `TypeError`) → логирование + `JobNotFoundError`. Pydantic-вариант предпочтительнее: схема валидируется автоматически.

### 🟠 BE-4 [HIGH] Хрупкий fallback на поиск исходного файла в ytdlp_client
**Файл:** `backend/app/integrations/ytdlp_client.py:102-106`
**Проблема:** Если `ydl.prepare_filename()` вернул несуществующий путь, код берёт **первый попавшийся** `source.*` в директории. При параллельных задачах в одной директории возможна гонка/выдача чужого файла.
**Фикс:** Каждая job работает в собственной директории `tmp_dir / job_id /` (это уже так). Усилить: если `prepare_filename()` не нашёл, искать по `glob("source.*")` **только в job-dir**, проверять что файл единственный, иначе `ExtractionFailed`.

### 🟠 BE-5 [HIGH] Hardcoded `/tmp/mp3craft` в config — не работает на Windows
**Файл:** `backend/app/core/config.py:28`
**Фикс:** `tmp_dir: Path = Field(default_factory=lambda: Path(tempfile.gettempdir()) / "mp3craft")`
Это unblock'ит локальный запуск на Windows-машинах + не сломает Docker (где уже есть `/tmp`).

### 🟡 BE-6 [MEDIUM] stderr ffmpeg обрезается до 500 символов в логах
**Файл:** `backend/app/services/audio_converter.py:42-52`
**Фикс:** Логировать полный stderr через `logger.error(..., stderr=err)`, обрезать только в user-facing message.

### 🟡 BE-7 [MEDIUM] `get_settings()` зовётся внутри `@field_validator` на каждом запросе
**Файл:** `backend/app/schemas/youtube.py:15-22`
**Проблема:** `get_settings()` уже `@lru_cache` (стандартный паттерн), так что цена низкая. Но семантически валидатор схемы зависит от global state — это анти-паттерн. Выносить allowed_hosts в Pydantic Settings приемлемо, но более чистое решение — валидация в Service-слое.
**Фикс (опционально):** Перенести whitelist-проверку из `JobCreateRequest.field_validator` в `YouTubeService.create_job()` с отдельным `InvalidUrlError`.

---

## FLUTTER — реальные проблемы

### 🔴 FE-1 [CRITICAL] Silent data loss в HistoryBloc — игнор Either
**Файл:** `mobile/lib/features/history/presentation/bloc/history_bloc.dart:41-51`
**Проблема:** `_onAdd` и `_onDelete` вызывают usecase, возвращающий `Either<Failure, ...>`, но **не проверяют результат**. При сбое БД пользователь видит "успех", элемент остаётся в истории.
**Фикс:**
```dart
Future<void> _onDelete(HistoryItemDeleted event, Emitter<HistoryState> emit) async {
  final result = await _deleteItem(event.id);
  result.fold(
    (failure) => emit(HistoryError(failure.message)),
    (_) => add(const HistoryLoadRequested()),
  );
}
```
Аналогично для `_onAdd`. И добавить unit-тест на Left-ветку.

### 🟠 FE-2 [HIGH] StreamSubscription без сохранения и cancel
**Файлы:**
- `mobile/lib/features/result/presentation/pages/result_page.dart:51-64`
- `mobile/lib/features/crop/presentation/pages/crop_page.dart:49-52`

**Проблема:** `_player.positionStream.listen(...)` без сохранения возврата. На практике `_player.dispose()` закроет streams, но при early dispose / переходе по deeplink возможны вызовы `setState()` после dispose (защищены `mounted`, но это работает по случайности — best practice требует cancel).
**Фикс:**
```dart
final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
_subs.add(_player.positionStream.listen(...));
_subs.add(_player.playerStateStream.listen(...));

@override
void dispose() {
  for (final s in _subs) { s.cancel(); }
  _player.dispose();
  super.dispose();
}
```

### 🟠 FE-3 [HIGH] Неиспользуемая `_pollSub` в YoutubeBloc
**Файл:** `mobile/lib/features/youtube/presentation/bloc/youtube_bloc.dart:34`
**Проблема:** Объявлена `StreamSubscription? _pollSub;`, но никогда не присваивается. `close()` зовёт `_pollSub?.cancel()` — мёртвый код, скрывающий потенциальный баг (если кто-то добавит `.listen()` с другим именем).
**Фикс:** Удалить `_pollSub` и `_pollSub?.cancel()` из `close()`.

### 🟠 FE-4 [HIGH] Magic numbers для UI-геометрии вне `app_dimens.dart`
**Файлы:** `result_page.dart`, `crop_page.dart` — позиционирование декоративного эллипса (`Positioned(left: -232, top: -617, width: 839, height: 839)`), полупрозрачные цвета (`Color(0x1AFFFFFF)`, `Color(0x0DFFFFFF)`, `Color(0x40FFFFFF)`) и др.
**Проблема:** Нарушает правило из CLAUDE.md §6.4: «никаких magic numbers в виджетах». На iPad возможны визуальные баги.
**Фикс:**
1. Вынести позиционирование эллипса в `AppDimens` (`ambientEllipseOffset`, `ambientEllipseSize`).
2. Добавить в `AppColors` константы `surfaceOverlay05/10/25` для повторяющихся `Color(0xNNFFFFFF)`.
3. Проверить визуально на iPad-симуляторе.

### 🟡 FE-5 [MEDIUM] Длинные файлы pages (500+ строк)
**Файлы:** `result_page.dart`, `crop_page.dart`
**Фикс:** Декомпозировать вложенные приватные классы (`_PlayerBar`, `_Trimmer`, `_WaveformVisualizer`) в отдельные файлы в `presentation/widgets/`. Не блокирует функциональность — оставить на followup.

### 🟡 FE-6 [MEDIUM] `_Trimmer` — drag-логика без декомпозиции
**Файл:** `crop_page.dart:323-384`
**Проблема:** 60+ строк вычислений `dx → ms` для трёх видов drag (start/end/range). Не покрыто unit-тестами.
**Фикс:** Извлечь в `CropTrimmerLogic` (pure-dart class в domain/utils) с методами и unit-тестами на граничные случаи (`min < start < end < max`, drag за пределы, swap при пересечении).

### 🟡 FE-7 [MEDIUM] Двойная номенклатура в `AppDimens`
**Файл:** `mobile/lib/app/theme/app_dimens.dart`
**Проблема:** `space12` и `spaceMd` оба = 12 px и используются параллельно.
**Фикс:** Выбрать **одну** систему (semantic: `spaceXs/Sm/Md/Lg/Xl`) и заменить все usage. Удалить дубли.

---

## Исключено из плана (false positives)

- **«Missing Content-Disposition» в `youtube.py:60-65`** — FastAPI `FileResponse(filename=...)` автоматически добавляет `Content-Disposition: attachment; filename="..."`. Не является дефектом.
- **«Race в `_share` после await»** в `result_page.dart:103-119` — `mounted` уже проверяется перед каждым использованием context. Корректно.
- **«context.read в initState»** в `youtube_page.dart:28` — это рекомендуемый паттерн для one-shot triggers, проблемой не является.
- **«ClassVar `job_timeout` в `WorkerSettings`»** — это и есть рекомендуемый паттерн arq (config через class attributes).

---

## План работ

### Фазы исполнения

**Phase A — Backend critical/high (db-agent не нужен; миграции нет)**
- Делегат: `python-dev`
- Задачи: BE-1, BE-2, BE-3, BE-4, BE-5
- Файлы:
  - `backend/app/services/youtube_service.py` — границы tmp_dir + UUID-валидация в delete
  - `backend/app/workers/tasks.py` — узкий exception catch + re-raise
  - `backend/app/repositories/job_repository.py` — try/except или Pydantic-Job
  - `backend/app/domain/job.py` — опционально миграция на `BaseModel`
  - `backend/app/integrations/ytdlp_client.py` — fallback search в job-dir с проверкой
  - `backend/app/core/config.py` — `tempfile.gettempdir()`

**Phase B — Flutter critical/high**
- Делегат: `python-dev` (агента flutter-dev в проекте нет; выполнит универсал, либо ручной фикс)
- Задачи: FE-1, FE-2, FE-3, FE-4
- Файлы:
  - `mobile/lib/features/history/presentation/bloc/history_bloc.dart` — Either fold
  - `mobile/lib/features/result/presentation/pages/result_page.dart` — sub list + cancel
  - `mobile/lib/features/crop/presentation/pages/crop_page.dart` — sub list + cancel
  - `mobile/lib/features/youtube/presentation/bloc/youtube_bloc.dart` — удаление мёртвого `_pollSub`
  - `mobile/lib/app/theme/app_dimens.dart` — `ambientEllipseOffset/Size`
  - `mobile/lib/app/theme/app_colors.dart` — `surfaceOverlay*` константы

**Phase C — Тесты**
- Делегат: `python-tester` (backend) + ручные Flutter тесты
- Backend: regression-тесты на BE-1 (попытка скачать с подменённым `file_path` → 404), BE-3 (повреждённый JSON в Redis → JobNotFoundError, не 500), BE-2 (worker не падает на доменных ошибках, фейлит задачу с правильным `error_code`)
- Flutter: unit-тест на `HistoryBloc._onDelete` Left-ветку (mock UseCase возвращает `Left(Failure)` → state = `HistoryError`)

**Phase D — Gate-чек**
- `cd backend && pytest -x --cov=app --cov-fail-under=80`
- `ruff check app && ruff format --check app`
- `mypy app --strict`
- `cd mobile && flutter analyze && flutter test`
- Ручной запуск iOS-симулятора: проверить что Result/Crop экраны не крашатся при быстрой навигации назад.

**Phase E — Medium refactor (опционально, отдельный коммит)**
- BE-6, BE-7, FE-5, FE-6, FE-7 — не блокируют, делать после критичных.

### Порядок коммитов

```
fix(service): защитить выдачу файла от path traversal (BE-1)
fix(worker): сузить exception handling и сохранить traceback (BE-2)
fix(repo): валидировать JSON из Redis при десериализации Job (BE-3)
fix(integration): искать source-файл только в job-dir (BE-4)
fix(core): использовать tempfile.gettempdir() для tmp_dir (BE-5)
fix(ui): обрабатывать Failure в HistoryBloc через Either.fold (FE-1)
fix(ui): cancel StreamSubscription в Result/Crop pages (FE-2)
chore(ui): удалить мёртвую _pollSub из YoutubeBloc (FE-3)
refactor(ui): вынести magic numbers геометрии в AppDimens/AppColors (FE-4)
test: regression-тесты для path traversal и Redis schema-drift
```

---

## Верификация (end-to-end)

1. **Path traversal (BE-1):**
   ```bash
   redis-cli SET "job:<uuid>" '{"file_path":"/etc/passwd","status":"completed",...}'
   curl http://localhost:8000/api/v1/youtube/jobs/<uuid>/file
   # Ожидаем: 404 "Файл вне разрешённой директории", не /etc/passwd
   ```
2. **Schema-drift (BE-3):**
   ```bash
   redis-cli SET "job:<uuid>" '{"broken":"json"}'
   curl http://localhost:8000/api/v1/youtube/jobs/<uuid>
   # Ожидаем: 404, не 500
   ```
3. **Worker exception (BE-2):**
   - Запустить задачу с заведомо bot-detected URL → задача `failed`, `error_code=BOT_DETECTED`, worker продолжает обрабатывать очередь.
4. **HistoryBloc failure (FE-1):**
   - Mock `DeleteHistoryItemUseCase.call()` → `Left(DatabaseFailure)` → state переходит в `HistoryError`, элемент НЕ удалён.
5. **StreamSubscription leak (FE-2):**
   - Открыть Result-экран, быстро нажать back до полной загрузки → нет лога `setState() called after dispose()`.
6. **iPad UI (FE-4):**
   - `flutter run -d <ipad-simulator-id>` → Result/Crop экраны выглядят корректно, ambient-эллипс не уезжает.

---

## Критичные файлы для модификации

**Backend:**
- `backend/app/services/youtube_service.py`
- `backend/app/workers/tasks.py`
- `backend/app/repositories/job_repository.py`
- `backend/app/integrations/ytdlp_client.py`
- `backend/app/core/config.py`
- `backend/app/domain/job.py` (опционально)
- `backend/tests/test_youtube_*.py` — regression тесты

**Flutter:**
- `mobile/lib/features/history/presentation/bloc/history_bloc.dart`
- `mobile/lib/features/result/presentation/pages/result_page.dart`
- `mobile/lib/features/crop/presentation/pages/crop_page.dart`
- `mobile/lib/features/youtube/presentation/bloc/youtube_bloc.dart`
- `mobile/lib/app/theme/app_dimens.dart`
- `mobile/lib/app/theme/app_colors.dart`
- `mobile/test/features/history/history_bloc_test.dart` — Left-ветка

---

## Оценка трудозатрат

| Phase | Объём | Время |
|---|---|---|
| A — Backend critical/high | 5 фиксов, ~150 строк | 2-3 ч |
| B — Flutter critical/high | 4 фикса, ~80 строк | 1.5-2 ч |
| C — Тесты | 6-8 тестов | 1.5 ч |
| D — Gate + ручная QA | — | 30 мин |
| E — Medium (опционально) | 4 рефактора | 2-3 ч |

**Итого критичный блок (A+B+C+D): ~6 часов.**
