# syntax=docker/dockerfile:1.4

FROM python:3.13-slim-bookworm AS base

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser

FROM base AS builder

# Try to use uv first, fallback to pip if it fails
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set environment variables
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Copy dependency files
COPY uv.lock pyproject.toml requirements.txt ./

# Try uv first, fallback to pip if it fails
RUN uv sync --locked --no-install-project --no-dev || \
    (echo "uv failed, falling back to pip" && \
     python -m venv .venv && \
     . .venv/bin/activate && \
     pip install --no-cache-dir -r requirements.txt)

# Copy the rest of the project
COPY . .

# Install the project in development mode
RUN . .venv/bin/activate && pip install -e .

FROM base

WORKDIR /app

# Copy installed environment and project from builder
COPY --from=builder --chown=appuser:appuser /app /app

# Switch to non-root user
USER appuser

# Activate the uv virtual environment
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH="/app:$PYTHONPATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health || exit 1

EXPOSE 8000

# Use exec form for proper signal handling
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]