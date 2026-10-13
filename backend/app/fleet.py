"""Bus registry helpers: seeding, lookup, and linking defects to buses."""

import logging
import uuid

from fastapi import HTTPException
from sqlalchemy import inspect, text
from sqlalchemy.exc import IntegrityError, OperationalError, ProgrammingError
from sqlmodel import Session, select

from .database import engine
from .fleet_data import BUS_NUMBERS
from .models import Bus, Defect

logger = logging.getLogger("uvicorn.error")


def normalise_number(number: str) -> str:
    """Compare bus numbers without spacing or case, so "22 п" and "22П" are
    the same bus rather than two."""
    return (number or "").strip().replace(" ", "").upper()


def find_bus(session: Session, number: str) -> Bus | None:
    return session.exec(
        select(Bus).where(Bus.number == normalise_number(number))
    ).first()


def require_bus(session: Session, number: str) -> Bus:
    """Resolve a number to a registered, in-service bus, or refuse the report.

    Filing against an unknown number is what produced duplicate vehicles when
    this was a free-text field.
    """
    bus = find_bus(session, number)
    if bus is None:
        raise HTTPException(
            status_code=422,
            detail=f"Unknown bus number '{number}'. Pick one from the fleet.",
        )
    if not bus.is_active:
        raise HTTPException(
            status_code=422,
            detail=f"Bus {bus.number} is not in service.",
        )
    return bus


def remove_line_number_registry() -> None:
    """Clear out the registry as it was before depots existed.

    It was seeded with JSP's *line* numbers (2, 22П, 65В…) under an
    urban/regional/night category, mistaking them for buses. Those rows are
    the ones without a depot. They are deleted rather than retired: they were
    never vehicles, and several collide with real garage numbers ("7" is both
    a line and a bus at Ѓорче Петров).

    Reports filed against them keep their bus_number text, so they still read
    as filed; only the link to the bogus row is cleared. Nothing re-links
    them afterwards, since line 7 and garage bus 7 are different things.
    """
    _drop_category_column()

    with Session(engine) as session:
        legacy = session.exec(
            select(Bus).where(Bus.depot == None)  # noqa: E711
        ).all()
        if not legacy:
            return

        legacy_ids = [bus.id for bus in legacy]
        reports = session.exec(
            select(Defect).where(Defect.bus_id.in_(legacy_ids))
        ).all()
        for defect in reports:
            defect.bus_id = None
            session.add(defect)
        for bus in legacy:
            session.delete(bus)
        session.commit()
        logger.info(
            "Removed %s line-number entries from the fleet registry; "
            "unlinked %s report(s), which keep the number they were filed with.",
            len(legacy),
            len(reports),
        )


def _drop_category_column() -> None:
    """The old `category` column is NOT NULL with no database default, so
    while it exists no new bus can be inserted. Dropped rather than left
    behind; it only ever held the urban/regional/night grouping of lines."""
    columns = {col["name"] for col in inspect(engine).get_columns("bus")}
    if "category" not in columns:
        return
    try:
        with engine.begin() as connection:
            connection.execute(text('ALTER TABLE "bus" DROP COLUMN "category"'))
    except (OperationalError, ProgrammingError):
        # Another worker dropped it between the inspection and now.
        return
    logger.info("Dropped the old bus.category column.")


def seed_fleet() -> None:
    """Load JSP's garage numbers for both depots on first start.

    Only ever adds: a number a dispatcher has since retired or moved to the
    other depot must not be reset on the next restart.
    """
    with Session(engine) as session:
        existing = {bus.number for bus in session.exec(select(Bus)).all()}
        added = 0
        for depot, numbers in BUS_NUMBERS.items():
            for number in numbers:
                normalised = normalise_number(number)
                if normalised in existing:
                    continue
                session.add(
                    Bus(
                        id=uuid.uuid4().hex,
                        number=normalised,
                        depot=depot,
                    )
                )
                existing.add(normalised)
                added += 1
        if added:
            try:
                session.commit()
            except IntegrityError:
                # Another worker seeded first; its rows are identical.
                session.rollback()
                return
            logger.info("Seeded %s buses into the fleet registry.", added)
