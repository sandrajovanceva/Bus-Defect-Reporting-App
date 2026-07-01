"""Database tables."""

from datetime import datetime
from typing import List, Optional

from sqlalchemy import Column, JSON
from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.utcnow()


class User(SQLModel, table=True):
    id: str = Field(primary_key=True)
    email: str = Field(index=True, unique=True)
    hashed_password: str
    full_name: str
    role: str = "driver"  # "driver" | "dispatcher"
    is_active: bool = True
    assigned_bus: Optional[str] = None
    assigned_route: Optional[str] = None
    created_at: datetime = Field(default_factory=utcnow)


class Defect(SQLModel, table=True):
    id: str = Field(primary_key=True)
    bus_number: str
    type: str
    priority: str
    status: str = "newReport"
    description: str
    department: str
    submitted_by_id: str = Field(index=True)
    submitted_by_name: str
    image_base64: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    history: List[dict] = Field(default_factory=list, sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)
