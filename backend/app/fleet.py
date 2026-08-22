"""Bus registry helpers: seeding, lookup, and linking defects to buses."""

import logging
import uuid

from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
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


def seed_fleet() -> None:
    """Load JSP's published bus numbers on first start.

    Only ever adds: a number a dispatcher has since retired or renamed must
    not come back on the next restart.
    """
    with Session(engine) as session:
        existing = {bus.number for bus in session.exec(select(Bus)).all()}
        added = 0
        for category, numbers in BUS_NUMBERS.items():
            for number in numbers:
                normalised = normalise_number(number)
                if normalised in existing:
                    continue
                session.add(
                    Bus(
                        id=uuid.uuid4().hex,
                        number=normalised,
                        category=category,
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


def link_existing_defects() -> None:
    """Attach defects filed before the registry existed to their bus.

    Anything whose number is not in the registry keeps a null bus_id rather
    than inventing a bus: those are the typos the registry exists to prevent,
    and a dispatcher should see and fix them.
    """
    with Session(engine) as session:
        unlinked = session.exec(
            select(Defect).where(Defect.bus_id == None)  # noqa: E711
        ).all()
        if not unlinked:
            return

        by_number = {
            bus.number: bus.id for bus in session.exec(select(Bus)).all()
        }
        linked = 0
        for defect in unlinked:
            bus_id = by_number.get(normalise_number(defect.bus_number))
            if bus_id:
                defect.bus_id = bus_id
                session.add(defect)
                linked += 1

        if linked:
            session.commit()
        orphans = len(unlinked) - linked
        logger.info(
            "Linked %s defect(s) to buses; %s left unmatched.", linked, orphans
        )
