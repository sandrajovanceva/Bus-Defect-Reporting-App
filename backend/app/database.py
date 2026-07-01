"""Database engine and session helpers (SQLite for dev, Postgres in prod)."""

from sqlmodel import Session, SQLModel, create_engine

from .config import settings

# SQLite needs check_same_thread=False for FastAPI's threadpool; other engines
# (e.g. Postgres) must not receive that argument.
_connect_args = (
    {"check_same_thread": False}
    if settings.database_url.startswith("sqlite")
    else {}
)

engine = create_engine(
    settings.database_url,
    echo=False,
    pool_pre_ping=True,
    connect_args=_connect_args,
)


def init_db() -> None:
    from . import models  # noqa: F401  (register tables before create_all)

    SQLModel.metadata.create_all(engine)


def get_session():
    with Session(engine) as session:
        yield session
