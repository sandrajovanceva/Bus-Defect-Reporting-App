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
    assigned_bus: Optional[str] = None
    assigned_route: Optional[str] = None


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    role: Optional[str] = None
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
    assigned_bus: Optional[str] = None
    assigned_route: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead


# --- defects ---
class HistoryEntry(BaseModel):
    type: str
    description: str
    changed_by_name: str
    changed_at: datetime


class DefectCreate(BaseModel):
    bus_number: str
    driver_name: str
    type: str
    priority: str
    description: str
    image_base64: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class DefectSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    bus_number: str
    type: str
    priority: str
    status: str
    description: str
    department: str
    submitted_by_id: str
    submitted_by_name: str
    driver_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    created_at: datetime
    updated_at: datetime
    history: List[HistoryEntry] = []


class DefectDetail(DefectSummary):
    image_base64: Optional[str] = None


class StatusUpdate(BaseModel):
    status: str


class TypeUpdate(BaseModel):
    type: str
