FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY pyproject.toml ./
RUN pip install --upgrade pip hatchling && \
    pip install \
      "fastapi>=0.115.0" \
      "uvicorn[standard]>=0.30.0" \
      "gunicorn>=23.0.0" \
      "pydantic>=2.9.0" \
      "pydantic-settings>=2.5.0" \
      "redis>=5.1.0" \
      "arq>=0.26.1" \
      "slowapi>=0.1.9" \
      "yt-dlp>=2026.1.1" \
      "structlog>=24.4.0" \
      "python-multipart>=0.0.12" \
      "httpx>=0.27.0"


FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg curl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY app ./app

RUN useradd -m -u 1000 appuser && \
    mkdir -p /tmp/mp3craft && \
    chown -R appuser:appuser /app /tmp/mp3craft
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health || exit 1

CMD ["gunicorn", "app.main:app", \
     "-k", "uvicorn.workers.UvicornWorker", \
     "-b", "0.0.0.0:8000", \
     "-w", "2", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
