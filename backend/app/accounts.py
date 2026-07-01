"""User account creation and bootstrap logic (shared by API + startup)."""

import logging
import uuid

from fastapi import HTTPException
from sqlmodel import Session, select

from .config import settings
from .database import engine
from .models import User
from .security import hash_password

logger = logging.getLogger("uvicorn.error")

VALID_ROLES = {"driver", "dispatcher"}


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
    assigned_bus: str | None = None,
    assigned_route: str | None = None,
) -> User:
    email = email.strip().lower()
    if role not in VALID_ROLES:
        raise HTTPException(status_code=422, detail="Role must be 'driver' or 'dispatcher'")
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
        assigned_bus=assigned_bus,
        assigned_route=assigned_route,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


def ensure_bootstrap_admin() -> None:
    """Create the first dispatcher if the user table is empty."""
    with Session(engine) as session:
        if session.exec(select(User)).first() is not None:
            return
        create_user(
            session,
            email=settings.bootstrap_admin_email,
            password=settings.bootstrap_admin_password,
            full_name=settings.bootstrap_admin_name,
            role="dispatcher",
        )
        logger.warning(
            "Bootstrapped first dispatcher '%s'. Change its password after "
            "first login.",
            settings.bootstrap_admin_email,
        )
