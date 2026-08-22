"""Database engine and session helpers (SQLite for dev, Postgres in prod)."""

import logging

from sqlalchemy import inspect, text
from sqlmodel import Session, SQLModel, create_engine

from .config import settings

logger = logging.getLogger("uvicorn.error")

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


def _sql_type(column) -> str | None:
    """The column's DDL type, or None if it cannot be rendered for this
    dialect — in which case it is skipped rather than guessed at."""
    try:
        return column.type.compile(engine.dialect)
    except Exception:
        return None


def _add_missing_columns() -> None:
    """Bring existing tables up to date with the models.

    `create_all` creates tables that do not exist but never alters ones that
    do, so a database created before a field was added keeps failing on every
    query that selects it — "no such column: user.department" and friends.

    This adds any column the models declare and the table lacks. It is
    deliberately additive only: nothing is renamed, retyped or dropped, so it
    cannot lose data. Anything beyond that needs a real migration tool.
    """
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())

    for table in SQLModel.metadata.sorted_tables:
        if table.name not in existing_tables:
            continue  # create_all just made it, so it is already current.

        present = {col["name"] for col in inspector.get_columns(table.name)}
        for column in table.columns:
            if column.name in present:
                continue

            column_type = _sql_type(column)
            if column_type is None:
                logger.warning(
                    "Cannot add %s.%s automatically; migrate it by hand.",
                    table.name,
                    column.name,
                )
                continue

            # A column added to a table with rows must be nullable or carry a
            # default, so it is always added nullable regardless of the model.
            with engine.begin() as connection:
                connection.execute(
                    text(
                        f'ALTER TABLE "{table.name}" '
                        f'ADD COLUMN "{column.name}" {column_type}'
                    )
                )
            logger.info("Added missing column %s.%s", table.name, column.name)


def init_db() -> None:
    from . import models  # noqa: F401  (register tables before create_all)

    SQLModel.metadata.create_all(engine)
    _add_missing_columns()


def get_session():
    with Session(engine) as session:
        yield session
