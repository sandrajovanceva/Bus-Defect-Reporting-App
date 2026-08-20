"""The bus registry.

Everyone signed in can read it — a driver filing a report needs the list to
pick from — but only a dispatcher may change it.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from ..database import get_session
from ..deps import get_current_user
from ..fleet_data import BUS_CATEGORIES
from ..models import Bus, Defect, User
from ..schemas import BusCreate, BusRead, BusUpdate

router = APIRouter(prefix="/buses", tags=["buses"])


def _require_dispatcher(current: User) -> None:
    if current.role != "dispatcher":
        raise HTTPException(
            status_code=403, detail="Only dispatchers can change the fleet"
        )


def _normalise(number: str) -> str:
    """Bus numbers are compared without spacing or case so that "22 п" cannot
    be filed as a second bus alongside "22П"."""
    return number.strip().replace(" ", "").upper()


def _check_category(category: str) -> str:
    if category not in BUS_CATEGORIES:
        raise HTTPException(
            status_code=422,
            detail="Category must be one of: " + ", ".join(BUS_CATEGORIES),
        )
    return category


@router.get("", response_model=list[BusRead])
def list_buses(
    include_inactive: bool = False,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    statement = select(Bus)
    if not include_inactive:
        statement = statement.where(Bus.is_active == True)  # noqa: E712
    buses = session.exec(statement).all()
    # Numeric-first ordering, so 2 comes before 15 and "15А" follows "15".
    return sorted(buses, key=_sort_key)


def _sort_key(bus: Bus) -> tuple:
    digits = ""
    for char in bus.number:
        if char.isdigit():
            digits += char
        else:
            break
    return (int(digits) if digits else 9999, bus.number)


@router.post("", response_model=BusRead, status_code=201)
def create_bus(
    body: BusCreate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    _require_dispatcher(current)
    number = _normalise(body.number)
    if not number:
        raise HTTPException(status_code=422, detail="Bus number is required")

    existing = session.exec(select(Bus).where(Bus.number == number)).first()
    if existing:
        raise HTTPException(status_code=409, detail="That bus already exists")

    bus = Bus(
        id=uuid.uuid4().hex,
        number=number,
        category=_check_category(body.category),
        notes=body.notes,
    )
    session.add(bus)
    session.commit()
    session.refresh(bus)
    return bus


@router.patch("/{bus_id}", response_model=BusRead)
def update_bus(
    bus_id: str,
    body: BusUpdate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    _require_dispatcher(current)
    bus = session.get(Bus, bus_id)
    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found")

    if body.number is not None:
        number = _normalise(body.number)
        if not number:
            raise HTTPException(status_code=422, detail="Bus number is required")
        clash = session.exec(select(Bus).where(Bus.number == number)).first()
        if clash and clash.id != bus.id:
            raise HTTPException(
                status_code=409, detail="Another bus already has that number"
            )
        bus.number = number
    if body.category is not None:
        bus.category = _check_category(body.category)
    if body.is_active is not None:
        bus.is_active = body.is_active
    if body.notes is not None:
        bus.notes = body.notes

    session.add(bus)
    session.commit()
    session.refresh(bus)
    return bus


@router.delete("/{bus_id}", status_code=204)
def delete_bus(
    bus_id: str,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    _require_dispatcher(current)
    bus = session.get(Bus, bus_id)
    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found")

    # A bus with history is retired, never deleted: removing it would orphan
    # every report filed against it.
    reported = session.exec(select(Defect).where(Defect.bus_id == bus.id)).first()
    if reported:
        raise HTTPException(
            status_code=409,
            detail="This bus has defect reports. Deactivate it instead.",
        )

    session.delete(bus)
    session.commit()
