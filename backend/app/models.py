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
    role: str = "driver"  # "driver" | "dispatcher" | "service"
    is_active: bool = True
    # Which maintenance department a service worker belongs to; this scopes the
    # defects they can see and claim. Null for drivers and dispatchers.
    department: Optional[str] = None
    assigned_bus: Optional[str] = None
    assigned_route: Optional[str] = None
    created_at: datetime = Field(default_factory=utcnow)


class Bus(SQLModel, table=True):
    """A bus in the JSP fleet, identified by the number it runs under.

    The registry exists so a defect can only ever be filed against a number
    that actually exists: free text produced "22", "22 " and "бус 22" as three
    different vehicles.
    """

    id: str = Field(primary_key=True)
    number: str = Field(index=True, unique=True)
    # "urban" | "regional" | "night", as JSP groups them.
    category: str = "urban"
    is_active: bool = True
    notes: Optional[str] = None
    created_at: datetime = Field(default_factory=utcnow)


class Defect(SQLModel, table=True):
    id: str = Field(primary_key=True)
    # Kept alongside [bus_id] rather than replaced by it: a number can be
    # retired or reassigned, and an old report should still read as it was
    # filed.
    bus_number: str
    bus_id: Optional[str] = Field(default=None, index=True)
    type: str
    priority: str
    status: str = "newReport"
    description: str
    department: str
    submitted_by_id: str = Field(index=True)
    submitted_by_name: str
    # Name of the driver the defect is about. Usually entered by the
    # dispatcher filing the report on the driver's behalf (from their paper
    # card / phone call) rather than the driver logging in themselves.
    driver_name: Optional[str] = None
    # Service worker currently responsible for the repair. Null means the
    # defect is still sitting in its department's queue.
    assigned_to_id: Optional[str] = Field(default=None, index=True)
    assigned_to_name: Optional[str] = None
    image_base64: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    history: List[dict] = Field(default_factory=list, sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)
