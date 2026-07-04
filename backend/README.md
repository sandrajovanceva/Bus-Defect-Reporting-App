# Bus Defect Reporting API

FastAPI backend for the Flutter bus defect reporting app. Self-hosted REST API
with JWT auth and role-based access — no paid cloud services.

## Stack
- **FastAPI** — REST API with auto-generated Swagger docs at `/docs`
- **SQLModel** ORM — **SQLite** for local dev, **PostgreSQL** for production
- **JWT** auth (PyJWT) with `pbkdf2_sha256` password hashing
- Images stored as base64 (no object storage / billing needed)
- Config via environment variables / `.env` (pydantic-settings)

## Accounts & roles
- **No public sign-up.** Accounts are created by a dispatcher via `/users`.
- On first startup, if the user table is empty, a **bootstrap dispatcher** is
  created from `BOOTSTRAP_ADMIN_EMAIL` / `BOOTSTRAP_ADMIN_PASSWORD`
  (default `admin@jsp.mk` / `ChangeMe123!`). **Log in and change it, then
  create the real staff accounts.**
- Roles are `driver` and `dispatcher`, assigned explicitly (never inferred).

## Run locally (SQLite)

```bash
cd backend
python -m venv venv
venv\Scripts\python -m pip install -r requirements.txt        # Windows
venv\Scripts\python -m uvicorn app.main:app --port 8000 --reload
```

- API: `http://localhost:8000` · Docs: `http://localhost:8000/docs`

## Run with Docker + PostgreSQL (production-like)

```bash
cd backend
cp .env.example .env        # then edit SECRET_KEY, admin password, etc.
docker compose up --build   # starts Postgres + the API on :8000
```

Postgres data persists in the `pgdata` Docker volume. The API waits for the DB
to be healthy before starting.

## Configuration (`.env`)
| Variable | Purpose |
|---|---|
| `SECRET_KEY` | JWT signing key — **must** be a long random string in prod |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins, or `*` for dev |
| `DATABASE_URL` | `sqlite:///./bus_defects.db` or `postgresql+psycopg://…` |
| `BOOTSTRAP_ADMIN_EMAIL` / `_PASSWORD` | First dispatcher account |
| `POSTGRES_PASSWORD` | Password for the compose Postgres service |

## Endpoints
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/login` | – | Authenticate, returns JWT + user |
| GET | `/auth/me` | Bearer | Current user |
| GET | `/users` | Dispatcher | List staff accounts |
| POST | `/users` | Dispatcher | Create a driver/dispatcher account |
| PATCH | `/users/{id}` | Dispatcher | Update role/details/password/active |
| DELETE | `/users/{id}` | Dispatcher | Remove an account |
| GET | `/defects` | Bearer | List (dispatcher: all, driver: own) |
| POST | `/defects` | Bearer | Create a defect report |
| GET | `/defects/{id}` | Bearer | Single defect (with image) |
| PATCH | `/defects/{id}/status` | Dispatcher | Change status |
| PATCH | `/defects/{id}/type` | Dispatcher | Armatura classification: set the defect type/department |
| POST | `/defects/seed` | Bearer | Seed demo defects (dev/testing) |

## Backups (Postgres)
```bash
# Dump
docker compose exec db pg_dump -U jsp bus_defects > backup_$(date +%F).sql
# Restore
cat backup.sql | docker compose exec -T db psql -U jsp -d bus_defects
```

## Production checklist
- Set a strong `SECRET_KEY` and change the bootstrap admin password.
- Restrict `ALLOWED_ORIGINS` to the real frontend domain.
- Use Postgres (Docker compose above) and schedule `pg_dump` backups.
- Terminate HTTPS at a reverse proxy (nginx/Caddy/Traefik) in front of `:8080`.
