"""Defect report endpoints."""

import uuid
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ..database import get_session
from ..deps import get_current_user
from ..fleet import find_bus, require_bus
from ..models import Defect, User
from ..sample_data import SAMPLE_DEFECTS
from ..schemas import (
    DefectCreate,
    DefectDetail,
    DefectSummary,
    StatusUpdate,
    TypeUpdate,
)

router = APIRouter(prefix="/defects", tags=["defects"])

DEPARTMENT_BY_TYPE = {
    "unclassified": "unassigned",
    "electrical": "electrical",
    "lights": "electrical",
    "climate": "electrical",
    "mechanical": "mechanical",
    "brakes": "mechanical",
    "bodywork": "bodywork",
    "doors": "bodywork",
    "other": "general",
}

TYPE_LABELS = {
    "unclassified": "UNCLASSIFIED",
    "electrical": "ELECTRICAL",
    "lights": "LIGHTS",
    "climate": "HEATING/AC",
    "mechanical": "MECHANICAL",
    "brakes": "BRAKES",
    "bodywork": "BODYWORK",
    "doors": "DOORS",
    "other": "OTHER",
}

# Statuses mirror the physical workflow. A report is filed unclassified and
# goes straight to intake inspection (armaturaReview) — that is the first step in the
# real procedure, and nobody upstream decides the category. Intake inspection
# determines electrical / mechanical / bravari, which routes it to that
# department's queue (newReport). A worker there picks it up (inProgress),
# fixes and signs it off (resolved), and the main gate clears the bus back
# into traffic (returnedToService). A report can be rejected at any point.
STATUS_LABELS = {
    "newReport": "NEW",
    "armaturaReview": "AT INTAKE INSPECTION",
    "inProgress": "IN PROGRESS",
    "onHold": "ON HOLD",
    "resolved": "RESOLVED",
    "returnedToService": "RETURNED TO SERVICE",
    "rejected": "REJECTED",
}

# Only a classified defect can be claimed: while it is still at intake inspection
# nobody knows which department it belongs to, so there is no queue to take
# it from.
CLAIMABLE_STATUSES = {"newReport"}

# Statuses a service worker may set on a job assigned to them. Returning a bus
# to service and rejecting a report stay with the dispatcher.
SERVICE_STATUSES = {"inProgress", "onHold", "resolved"}

VALID_PRIORITIES = {"low", "medium", "high"}


def _bus_id_for(session, number: str) -> str | None:
    bus = find_bus(session, number)
    return bus.id if bus else None


def _new_id() -> str:
    return "D-" + uuid.uuid4().hex[:6].upper()


def _can_view(current: User, defect: Defect) -> bool:
    if current.role == "dispatcher":
        return True
    if current.role == "armatura":
        # Intake inspection needs the whole board: what is waiting to be classified,
        # and what it has already sent on.
        return True
    if current.role == "service":
        return defect.department == current.department
    return defect.submitted_by_id == current.id


def _visible_query(current: User):
    stmt = select(Defect)
    if current.role in ("dispatcher", "armatura"):
        # Dispatchers see the whole fleet; intake inspection needs the same board to
        # work its queue and follow what it has routed onward.
        pass
    elif current.role == "service":
        # Service workers only ever see their own department's defects.
        stmt = stmt.where(Defect.department == current.department)
    else:
        stmt = stmt.where(Defect.submitted_by_id == current.id)
    return stmt.order_by(Defect.created_at.desc())


@router.get("", response_model=list[DefectSummary])
def list_defects(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    return session.exec(_visible_query(current)).all()


@router.post("", response_model=DefectDetail, status_code=status.HTTP_201_CREATED)
def create_defect(
    body: DefectCreate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if not body.driver_name.strip():
        raise HTTPException(status_code=422, detail="Driver name is required")

    # The number must exist in the fleet registry. This is the check that
    # stops "22", "22 " and "бус 22" becoming three different buses.
    bus = require_bus(session, body.bus_number)

    now = datetime.utcnow()
    defect = Defect(
        id=_new_id(),
        bus_number=bus.number,
        bus_id=bus.id,
        # Whoever files the report does not decide the category: it goes in
        # unclassified and intake inspection determines it.
        type="unclassified",
        # A placeholder until intake inspection judges it; nothing acts on priority
        # while the report is still unclassified.
        priority="medium",
        status="armaturaReview",
        description=body.description.strip(),
        department="unassigned",
        submitted_by_id=current.id,
        submitted_by_name=current.full_name,
        driver_name=body.driver_name.strip(),
        image_base64=body.image_base64,
        address=(body.address or "").strip() or None,
        latitude=body.latitude,
        longitude=body.longitude,
        history=[
            {
                "type": "created",
                "meta": {"event": "submitted"},
                "description": "Report submitted; sent to intake inspection.",
                "changed_by_name": current.full_name,
                "changed_at": now.isoformat(),
            }
        ],
        created_at=now,
        updated_at=now,
    )
    session.add(defect)
    session.commit()
    session.refresh(defect)
    return defect


@router.post("/seed")
def seed_defects(
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    existing = session.exec(
        select(Defect).where(Defect.submitted_by_id == current.id)
    ).all()
    if existing:
        return {"seeded": 0, "existing": len(existing)}

    now = datetime.utcnow()
    for sample in SAMPLE_DEFECTS:
        created_at = now - timedelta(hours=sample["hours_ago"])
        history = [
            {
                "type": "created",
                "meta": {"event": "submitted"},
                "description": "Report submitted; sent to intake inspection.",
                "changed_by_name": current.full_name,
                "changed_at": created_at.isoformat(),
            }
        ]
        if sample["status"] != "newReport":
            history.append(
                {
                    "type": "statusChange",
                    "meta": {"from": "newReport", "to": sample["status"]},
                    "description": (
                        f"Status changed: NEW -> {STATUS_LABELS[sample['status']]}."
                    ),
                    "changed_by_name": "Диспечер",
                    "changed_at": (created_at + timedelta(hours=3)).isoformat(),
                }
            )
        session.add(
            Defect(
                id=_new_id(),
                bus_number=sample["bus_number"],
                bus_id=_bus_id_for(session, sample["bus_number"]),
                type=sample["type"],
                priority=sample["priority"],
                status=sample["status"],
                description=sample["description"],
                department=DEPARTMENT_BY_TYPE[sample["type"]],
                submitted_by_id=current.id,
                submitted_by_name=current.full_name,
                driver_name=sample.get("driver_name", "Возач"),
                latitude=sample["lat"],
                longitude=sample["lng"],
                history=history,
                created_at=created_at,
                updated_at=created_at,
            )
        )
    session.commit()
    return {"seeded": len(SAMPLE_DEFECTS), "existing": 0}


@router.get("/{defect_id}", response_model=DefectDetail)
def get_defect(
    defect_id: str,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    defect = session.get(Defect, defect_id)
    if not defect:
        raise HTTPException(status_code=404, detail="Defect not found")
    if not _can_view(current, defect):
        raise HTTPException(status_code=403, detail="Not allowed")
    return defect


@router.patch("/{defect_id}/status", response_model=DefectDetail)
def update_status(
    defect_id: str,
    body: StatusUpdate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if body.status not in STATUS_LABELS:
        raise HTTPException(status_code=422, detail="Unknown status")

    defect = session.get(Defect, defect_id)
    if not defect:
        raise HTTPException(status_code=404, detail="Defect not found")

    if current.role == "dispatcher":
        pass  # dispatchers drive the whole workflow
    elif current.role == "service":
        if defect.assigned_to_id != current.id:
            raise HTTPException(
                status_code=403, detail="You can only update jobs assigned to you"
            )
        if body.status not in SERVICE_STATUSES:
            raise HTTPException(
                status_code=403,
                detail=(
                    "Service workers can only set: "
                    + ", ".join(sorted(SERVICE_STATUSES))
                ),
            )
    else:
        raise HTTPException(status_code=403, detail="Not allowed to change status")

    previous = defect.status
    now = datetime.utcnow()
    defect.status = body.status
    defect.updated_at = now
    history = list(defect.history or [])
    history.append(
        {
            "type": "statusChange",
            "meta": {"from": previous, "to": body.status},
            "description": (
                f"Status changed: {STATUS_LABELS.get(previous, previous)} -> "
                f"{STATUS_LABELS[body.status]}."
            ),
            "changed_by_name": current.full_name,
            "changed_at": now.isoformat(),
        }
    )
    if body.note and body.note.strip():
        history.append(
            {
                "type": "note",
                "meta": {"event": "note"},
                "description": body.note.strip(),
                "changed_by_name": current.full_name,
                "changed_at": now.isoformat(),
            }
        )
    defect.history = history
    session.add(defect)
    session.commit()
    session.refresh(defect)
    return defect


@router.post("/{defect_id}/claim", response_model=DefectDetail)
def claim_defect(
    defect_id: str,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    """A service worker pulls a defect out of their department's queue and
    starts working on it."""
    if current.role != "service":
        raise HTTPException(
            status_code=403, detail="Only service workers can claim a defect"
        )

    defect = session.get(Defect, defect_id)
    if not defect:
        raise HTTPException(status_code=404, detail="Defect not found")
    if defect.department != current.department:
        raise HTTPException(
            status_code=403, detail="This defect belongs to another department"
        )
    if defect.assigned_to_id:
        raise HTTPException(
            status_code=409,
            detail=f"Already claimed by {defect.assigned_to_name}",
        )
    if defect.status not in CLAIMABLE_STATUSES:
        raise HTTPException(
            status_code=409, detail="This defect is not waiting in the queue"
        )

    now = datetime.utcnow()
    defect.assigned_to_id = current.id
    defect.assigned_to_name = current.full_name
    defect.status = "inProgress"
    defect.updated_at = now
    history = list(defect.history or [])
    history.append(
        {
            "type": "assignment",
            "meta": {"event": "claimed", "worker": current.full_name},
            "description": f"Claimed by {current.full_name}; work started.",
            "changed_by_name": current.full_name,
            "changed_at": now.isoformat(),
        }
    )
    defect.history = history
    session.add(defect)
    session.commit()
    session.refresh(defect)
    return defect


@router.post("/{defect_id}/release", response_model=DefectDetail)
def release_defect(
    defect_id: str,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    """Give an unfinished job back to the department queue."""
    defect = session.get(Defect, defect_id)
    if not defect:
        raise HTTPException(status_code=404, detail="Defect not found")

    is_owner = current.role == "service" and defect.assigned_to_id == current.id
    if not (is_owner or current.role == "dispatcher"):
        raise HTTPException(
            status_code=403, detail="Only the assigned worker can release this job"
        )
    if not defect.assigned_to_id:
        raise HTTPException(status_code=409, detail="This defect is not assigned")

    now = datetime.utcnow()
    previous_name = defect.assigned_to_name
    defect.assigned_to_id = None
    defect.assigned_to_name = None
    # Back to its own department's queue. It has already been classified, so
    # it must not travel back to intake inspection.
    defect.status = "newReport"
    defect.updated_at = now
    history = list(defect.history or [])
    history.append(
        {
            "type": "assignment",
            "meta": {
                "event": "released",
                "worker": previous_name,
                "department": defect.department,
            },
            "description": (
                f"Released by {previous_name} back to the "
                f"{defect.department} queue."
            ),
            "changed_by_name": current.full_name,
            "changed_at": now.isoformat(),
        }
    )
    defect.history = history
    session.add(defect)
    session.commit()
    session.refresh(defect)
    return defect


@router.patch("/{defect_id}/type", response_model=DefectDetail)
def reclassify_defect(
    defect_id: str,
    body: TypeUpdate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    """Intake inspection's classification: determines the real defect category and
    therefore which department the report is routed to.

    This is the first step of the physical procedure, so it belongs to the
    intake inspection (Приемна контрола). A dispatcher keeps access as the system's
    administrator, to correct a misclassification after the fact.
    """
    if current.role not in ("armatura", "dispatcher"):
        raise HTTPException(
            status_code=403,
            detail="Only intake inspection can classify a defect",
        )
    if body.type not in DEPARTMENT_BY_TYPE:
        raise HTTPException(status_code=422, detail="Unknown defect type")
    if body.type == "unclassified":
        raise HTTPException(
            status_code=422, detail="Pick an actual category, not unclassified"
        )
    if body.priority is not None and body.priority not in VALID_PRIORITIES:
        raise HTTPException(
            status_code=422,
            detail="Priority must be one of: " + ", ".join(sorted(VALID_PRIORITIES)),
        )

    defect = session.get(Defect, defect_id)
    if not defect:
        raise HTTPException(status_code=404, detail="Defect not found")

    previous_type = defect.type
    previous_priority = defect.priority
    now = datetime.utcnow()
    defect.type = body.type
    if body.priority is not None:
        defect.priority = body.priority
    defect.department = DEPARTMENT_BY_TYPE[body.type]
    # Classifying is what puts the report into a department queue, so an
    # unclaimed report waiting at intake inspection becomes claimable here.
    if defect.status == "armaturaReview":
        defect.status = "newReport"
    defect.updated_at = now
    history = list(defect.history or [])
    history.append(
        {
            "type": "departmentChange",
            "meta": {
                "from_type": previous_type,
                "to_type": body.type,
                "department": defect.department,
                "from_priority": previous_priority,
                "to_priority": defect.priority,
            },
            "description": (
                f"Classified at intake inspection: {TYPE_LABELS.get(previous_type, previous_type)} "
                f"-> {TYPE_LABELS[body.type]} ({defect.department})."
                + (
                    f" Priority {previous_priority} -> {defect.priority}."
                    if defect.priority != previous_priority
                    else ""
                )
            ),
            "changed_by_name": current.full_name,
            "changed_at": now.isoformat(),
        }
    )
    defect.history = history
    session.add(defect)
    session.commit()
    session.refresh(defect)
    return defect
