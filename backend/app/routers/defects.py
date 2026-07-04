"""Defect report endpoints."""

import uuid
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ..database import get_session
from ..deps import get_current_user
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

# Statuses mirror the physical workflow: a report comes in (newReport), goes
# to the Арматура (fittings) department which determines the defect category
# — electrical / mechanical / bravari (armaturaReview), gets assigned and
# worked on (inProgress), is fixed and signed off (resolved), and finally
# cleared at the main gate to rejoin traffic (returnedToService). A report
# can be rejected at any point.
STATUS_LABELS = {
    "newReport": "NEW",
    "armaturaReview": "AT ARMATURA",
    "inProgress": "IN PROGRESS",
    "resolved": "RESOLVED",
    "returnedToService": "RETURNED TO SERVICE",
    "rejected": "REJECTED",
}


def _new_id() -> str:
    return "D-" + uuid.uuid4().hex[:6].upper()


def _visible_query(current: User):
    stmt = select(Defect)
    # Dispatchers see everything; drivers only their own reports.
    if current.role != "dispatcher":
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
    if body.type not in DEPARTMENT_BY_TYPE:
        raise HTTPException(status_code=422, detail="Unknown defect type")
    if not body.driver_name.strip():
        raise HTTPException(status_code=422, detail="Driver name is required")

    now = datetime.utcnow()
    defect = Defect(
        id=_new_id(),
        bus_number=body.bus_number.strip(),
        type=body.type,
        priority=body.priority,
        status="newReport",
        description=body.description.strip(),
        department=DEPARTMENT_BY_TYPE[body.type],
        submitted_by_id=current.id,
        submitted_by_name=current.full_name,
        driver_name=body.driver_name.strip(),
        image_base64=body.image_base64,
        latitude=body.latitude,
        longitude=body.longitude,
        history=[
            {
                "type": "created",
                "description": "Report submitted.",
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
                "description": "Report submitted.",
                "changed_by_name": current.full_name,
                "changed_at": created_at.isoformat(),
            }
        ]
        if sample["status"] != "newReport":
            history.append(
                {
                    "type": "statusChange",
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
    if current.role != "dispatcher" and defect.submitted_by_id != current.id:
        raise HTTPException(status_code=403, detail="Not allowed")
    return defect


@router.patch("/{defect_id}/status", response_model=DefectDetail)
def update_status(
    defect_id: str,
    body: StatusUpdate,
    current: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if current.role != "dispatcher":
        raise HTTPException(
            status_code=403, detail="Only dispatchers can change status"
        )
    if body.status not in STATUS_LABELS:
        raise HTTPException(status_code=422, detail="Unknown status")

    defect = session.get(Defect, defect_id)
    if not defect:
        raise HTTPException(status_code=404, detail="Defect not found")

    previous = defect.status
    now = datetime.utcnow()
    defect.status = body.status
    defect.updated_at = now
    history = list(defect.history or [])
    history.append(
        {
            "type": "statusChange",
            "description": (
                f"Status changed: {STATUS_LABELS.get(previous, previous)} -> "
                f"{STATUS_LABELS[body.status]}."
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
    """Armatura-department classification: pins down the actual defect
    category (and therefore which department it's routed to), which may
    differ from whatever the reporter guessed when filing the report."""
    if current.role != "dispatcher":
        raise HTTPException(
            status_code=403, detail="Only dispatchers can classify a defect"
        )
    if body.type not in DEPARTMENT_BY_TYPE:
        raise HTTPException(status_code=422, detail="Unknown defect type")
    if body.type == "unclassified":
        raise HTTPException(
            status_code=422, detail="Pick an actual category, not unclassified"
        )

    defect = session.get(Defect, defect_id)
    if not defect:
        raise HTTPException(status_code=404, detail="Defect not found")

    previous_type = defect.type
    now = datetime.utcnow()
    defect.type = body.type
    defect.department = DEPARTMENT_BY_TYPE[body.type]
    defect.updated_at = now
    history = list(defect.history or [])
    history.append(
        {
            "type": "departmentChange",
            "description": (
                f"Classified by Armatura: {TYPE_LABELS.get(previous_type, previous_type)} "
                f"-> {TYPE_LABELS[body.type]} ({defect.department})."
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
