"""User account creation and bootstrap logic (shared by API + startup)."""

import logging
import uuid

from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session, select

from .config import settings
from .database import engine
from .models import User
from .security import hash_password

logger = logging.getLogger("uvicorn.error")

# "armatura" is Приемна контрола (intake inspection): the first stop after a
# report is filed, where the defect category — electrical / mechanical /
# bravari — is determined and the report routed onward. The value is a
# leftover from when the role was wrongly named after Арматура, which is a
# separate JSP department; it stays because it is stored on every account.
VALID_ROLES = {"driver", "dispatcher", "service", "armatura"}

# Departments a service worker can belong to. "unassigned" is reserved for
# defects awaiting intake inspection and is never a worker's department.
VALID_DEPARTMENTS = {"electrical", "mechanical", "bodywork", "general"}


def validate_department(role: str, department: str | None) -> str | None:
    """Service workers must belong to a real department; others must not."""
    if role != "service":
        return None
    if department not in VALID_DEPARTMENTS:
        raise HTTPException(
            status_code=422,
            detail=(
                "A service worker needs a department: "
                + ", ".join(sorted(VALID_DEPARTMENTS))
            ),
        )
    return department


def validate_password(password: str) -> None:
    if len(password) < settings.min_password_length:
        raise HTTPException(
            status_code=422,
            detail=(
                "Password must be at least "
                f"{settings.min_password_length} characters"
            ),
        )


def create_user(
    session: Session,
    *,
    email: str,
    password: str,
    full_name: str | None = None,
    role: str = "driver",
    department: str | None = None,
    assigned_bus: str | None = None,
    assigned_route: str | None = None,
) -> User:
    email = email.strip().lower()
    if role not in VALID_ROLES:
        raise HTTPException(
            status_code=422,
            detail="Role must be one of: " + ", ".join(sorted(VALID_ROLES)),
        )
    department = validate_department(role, department)
    validate_password(password)

    existing = session.exec(select(User).where(User.email == email)).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    user = User(
        id=uuid.uuid4().hex,
        email=email,
        hashed_password=hash_password(password),
        full_name=(full_name or "").strip() or email.split("@")[0],
        role=role,
        department=department,
        assigned_bus=assigned_bus,
        assigned_route=assigned_route,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


def ensure_bootstrap_admin() -> None:
    """Create the first dispatcher if the user table is empty.

    A production server runs several workers and every one of them executes
    startup, so the "is it empty" check and the insert race each other. The
    unique index on email is what actually decides it; losing that race is
    the normal outcome for all but one worker, not an error.
    """
    with Session(engine) as session:
        if session.exec(select(User)).first() is not None:
            return
        try:
            create_user(
                session,
                email=settings.bootstrap_admin_email,
                password=settings.bootstrap_admin_password,
                full_name=settings.bootstrap_admin_name,
                role="dispatcher",
            )
        except IntegrityError:
            # Another worker won the race and created the same account.
            session.rollback()
            return
        except HTTPException as error:
            # A rejected password or malformed email leaves the deployment
            # with no way in at all, so it has to be loud. Swallowing this
            # silently is how you get a database nobody can sign in to.
            session.rollback()
            logger.error(
                "Could not create the bootstrap dispatcher '%s': %s. "
                "Fix BOOTSTRAP_ADMIN_EMAIL / BOOTSTRAP_ADMIN_PASSWORD and "
                "redeploy.",
                settings.bootstrap_admin_email,
                error.detail,
            )
            return
        logger.warning(
            "Bootstrapped first dispatcher '%s'. Change its password after "
            "first login.",
            settings.bootstrap_admin_email,
        )
