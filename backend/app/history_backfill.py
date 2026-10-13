"""One-off backfill: give old history entries the structured `meta` that
newer ones are written with.

Before `meta` existed the backend stored a finished English sentence and
nothing else, so those entries can never be shown in another language. The
sentences were machine-generated from a handful of fixed templates, so they
can be parsed back into the facts they were built from.

Runs on startup and only touches entries that have no `meta`, so it is safe to
run repeatedly. Anything it cannot parse is left alone and keeps falling back
to its English text.
"""

import logging
import re

from sqlmodel import Session, select

from .database import engine
from .models import Defect

logger = logging.getLogger("uvicorn.error")

# The label -> value maps the old sentences were rendered through.
STATUS_BY_LABEL = {
    "NEW": "newReport",
    "AT ARMATURA": "armaturaReview",
    "AT INTAKE INSPECTION": "armaturaReview",
    "IN PROGRESS": "inProgress",
    "ON HOLD": "onHold",
    "RESOLVED": "resolved",
    "RETURNED TO SERVICE": "returnedToService",
    "REJECTED": "rejected",
}

TYPE_BY_LABEL = {
    "UNCLASSIFIED": "unclassified",
    "ELECTRICAL": "electrical",
    "LIGHTS": "lights",
    "HEATING/AC": "climate",
    "MECHANICAL": "mechanical",
    "BRAKES": "brakes",
    "BODYWORK": "bodywork",
    "DOORS": "doors",
    "OTHER": "other",
}

_STATUS = re.compile(r"^Status changed: (.+?) -> (.+?)\.$")
_CLASSIFIED = re.compile(
    r"^Classified (?:by Armatura|at intake inspection): (.+?) -> (.+?) \((\w+)\)\."
    r"(?: Priority (\w+) -> (\w+)\.)?$"
)
_CLAIMED = re.compile(r"^Claimed by (.+?); work started\.$")
_RELEASED = re.compile(r"^Released by (.+?) back to the (\w+) queue\.$")


def _parse(entry: dict) -> dict | None:
    description = (entry.get("description") or "").strip()
    kind = entry.get("type")

    if kind == "created":
        return {"event": "submitted"}
    if kind == "note":
        return {"event": "note"}

    match = _STATUS.match(description)
    if match:
        before = STATUS_BY_LABEL.get(match.group(1))
        after = STATUS_BY_LABEL.get(match.group(2))
        if before and after:
            return {"from": before, "to": after}
        return None

    match = _CLASSIFIED.match(description)
    if match:
        to_type = TYPE_BY_LABEL.get(match.group(2))
        if not to_type:
            return None
        meta = {
            "from_type": TYPE_BY_LABEL.get(match.group(1), "unclassified"),
            "to_type": to_type,
            "department": match.group(3),
        }
        if match.group(4) and match.group(5):
            meta["from_priority"] = match.group(4)
            meta["to_priority"] = match.group(5)
        return meta

    match = _CLAIMED.match(description)
    if match:
        return {"event": "claimed", "worker": match.group(1)}

    match = _RELEASED.match(description)
    if match:
        return {
            "event": "released",
            "worker": match.group(1),
            "department": match.group(2),
        }

    return None


def backfill_history_meta() -> None:
    with Session(engine) as session:
        defects = session.exec(select(Defect)).all()
        filled = skipped = 0

        for defect in defects:
            history = list(defect.history or [])
            changed = False

            for index, entry in enumerate(history):
                if entry.get("meta"):
                    continue
                meta = _parse(entry)
                if meta is None:
                    skipped += 1
                    continue
                history[index] = {**entry, "meta": meta}
                filled += 1
                changed = True

            if changed:
                # Reassign so SQLAlchemy notices the JSON column changed.
                defect.history = history
                session.add(defect)

        if filled:
            session.commit()
            logger.info(
                "Backfilled %s history entrie(s); %s left as English text.",
                filled,
                skipped,
            )
