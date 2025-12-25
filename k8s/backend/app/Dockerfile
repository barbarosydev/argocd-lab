# syntax=docker/dockerfile:1
FROM python:3.11-slim AS base

# Install uv
RUN pip install uv

WORKDIR /app
COPY pyproject.toml /app/
RUN uv pip install -r pyproject.toml --system

COPY app /app/app

EXPOSE 8000
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

