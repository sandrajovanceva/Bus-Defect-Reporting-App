"""Request and response models."""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict


# --- auth ---
class RegisterRequest(BaseModel):
    email: str
    password: str
    full_name: Optional[str] = None
    role: Optional[str] = None


class LoginRequest(BaseModel):
    email: str
    password: str


class UserCreate(BaseModel):
    email: str
    password: str
    full_name: Optional[str] = None
    role: str = "driver"
    department: Optional[str] = None
    assigned_bus: Optional[str] = None
    assigned_route: Optional[str] = None


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    role: Optional[str] = None
    department: Optional[str] = None
    assigned_bus: Optional[str] = None
    assigned_route: Optional[str] = None
    is_active: Optional[bool] = None
    password: Optional[str] = None


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    full_name: str
    role: str
    is_active: bool = True
    department: Optional[str] = None
    assigned_bus: Optional[str] = None
    assigned_route: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead


# --- buses ---
class BusCreate(BaseModel):
    number: str
    category: str = "urban"
    notes: Optional[str] = None


class BusUpdate(BaseModel):
    number: Optional[str] = None
    category: Optional[str] = None
    is_active: Optional[bool] = None
    notes: Optional[str] = None


class BusRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    number: str
    category: str
    is_active: bool = True
    notes: Optional[str] = None


# --- defects ---
class HistoryEntry(BaseModel):
    type: str
    # Structured facts about the event. The client renders the sentence from
    # these in the reader's language; `description` is the English fallback
    # for entries written before this existed.
    meta: Optional[dict] = None
    description: str
    changed_by_name: str
    changed_at: datetime


class DefectCreate(BaseModel):
    bus_number: str
    driver_name: str
    # Neither type nor priority: both are Арматура's to determine once the
    # bus reaches the depot, so a report is always filed unclassified.
    description: str
    image_base64: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class DefectSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    bus_number: str
    bus_id: Optional[str] = None
    type: str
    priority: str
    status: str
    description: str
    department: str
    submitted_by_id: str
    submitted_by_name: str
    driver_name: Optional[str] = None
    assigned_to_id: Optional[str] = None
    assigned_to_name: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: datetime
    updated_at: datetime
    history: List[HistoryEntry] = []


class DefectDetail(DefectSummary):
    image_base64: Optional[str] = None


class StatusUpdate(BaseModel):
    status: str
    # Optional work note, e.g. "waiting for brake pads" when putting on hold.
    note: Optional[str] = None


class TypeUpdate(BaseModel):
    type: str
    # Арматура judges urgency at the same time as the category, so both are
    # set in one action rather than two.
    priority: Optional[str] = None
