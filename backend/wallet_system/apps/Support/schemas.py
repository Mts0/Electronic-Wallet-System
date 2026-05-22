# Support/schemas.py

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# ================== CALL CENTER ==================

class CallCenterBase(BaseModel):
    subject: str = Field(..., max_length=200)
    message: str


class CallCenterCreate(CallCenterBase):
    """
    إنشاء تذكرة داخلية من طرف موظف:
    - wallet_number: رقم محفظة العميل
    - assigned_to: رقم الموظف المسؤول
    """
    wallet_number: str = Field(..., max_length=100)
    assigned_to: int


class CallCenterUpdateStatus(BaseModel):
    status: str = Field(..., max_length=20)


class CallCenterReassign(BaseModel):
    assigned_to: int


class CallCenterOut(BaseModel):
    ticket_id: int
    user_id: int
    subject: str
    message: str
    status: Optional[str]
    assigned_to: int
    created_at: datetime

    class Config:
        from_attributes = True


# ================== NOTIFICATIONS ==================

class NotificationCreate(BaseModel):
    user_id: int
    title: str = Field(..., max_length=100)
    message: str


class NotificationOut(BaseModel):
    notification_id: int
    user_id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    message: str
