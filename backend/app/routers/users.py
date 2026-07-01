"""Dispatcher-only staff account management."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ..accounts import VALID_ROLES, create_user, validate_password
from ..database import get_session
from ..deps import get_current_dispatcher
from ..models import User
from ..schemas import UserCreate, UserRead, UserUpdate
from ..security import hash_password

router = APIRouter(prefix="/users", tags=["users"])


@router.get("", response_model=list[UserRead])
def list_users(
    _: User = Depends(get_current_dispatcher),
    session: Session = Depends(get_session),
):
    return session.exec(select(User).order_by(User.created_at)).all()


@router.post("", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def create(
    body: UserCreate,
    _: User = Depends(get_current_dispatcher),
    session: Session = Depends(get_session),
):
    return create_user(
        session,
        email=body.email,
        password=body.password,
        full_name=body.full_name,
        role=body.role,
        assigned_bus=body.assigned_bus,
        assigned_route=body.assigned_route,
    )


@router.patch("/{user_id}", response_model=UserRead)
def update(
    user_id: str,
    body: UserUpdate,
    current: User = Depends(get_current_dispatcher),
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if body.role is not None:
        if body.role not in VALID_ROLES:
            raise HTTPException(status_code=422, detail="Invalid role")
        if user.id == current.id and body.role != "dispatcher":
            raise HTTPException(
                status_code=400, detail="You cannot change your own role"
            )
        user.role = body.role

    if body.full_name is not None:
        user.full_name = body.full_name.strip() or user.full_name
    if body.assigned_bus is not None:
        user.assigned_bus = body.assigned_bus
    if body.assigned_route is not None:
        user.assigned_route = body.assigned_route

    if body.is_active is not None:
        if user.id == current.id and not body.is_active:
            raise HTTPException(
                status_code=400, detail="You cannot deactivate your own account"
            )
        user.is_active = body.is_active

    if body.password:
        validate_password(body.password)
        user.hashed_password = hash_password(body.password)

    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete(
    user_id: str,
    current: User = Depends(get_current_dispatcher),
    session: Session = Depends(get_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == current.id:
        raise HTTPException(
            status_code=400, detail="You cannot delete your own account"
        )
    session.delete(user)
    session.commit()
