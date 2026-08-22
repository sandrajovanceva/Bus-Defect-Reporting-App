FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8080

# Production server: gunicorn managing uvicorn workers.
#
# Shell form, so $PORT expands. Hosts that assign the port — Render, Fly,
# Cloud Run — pass it in the environment and will not route traffic to a
# container listening anywhere else. Falls back to 8080 for docker-compose
# and local runs, which map the port themselves.
CMD gunicorn app.main:app \
    -k uvicorn.workers.UvicornWorker \
    -b 0.0.0.0:${PORT:-8080} \
    -w ${WEB_CONCURRENCY:-2}
