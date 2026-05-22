from datetime import datetime, date
from typing import Optional

from pydantic import BaseModel, Field
from enum import Enum


class IDType(str, Enum):
    NATIONAL_ID = "NATIONAL_ID"
    PASSPORT = "PASSPORT"


class KYCStatus(str, Enum):
    DRAFT = "DRAFT"
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


# ====== طلب KYC من العميل (البيانات أولًا) ======

class UserKYCDraftCreate(BaseModel):
    """الخطوة 1: بيانات الهوية فقط (بدون صور)."""
    id_type: IDType
    id_number: str = Field(..., max_length=50)
    id_expiry: date
    nationality: str = Field(..., max_length=50)
    country: Optional[str] = Field(None, max_length=30)
    city: str = Field(..., max_length=20)
    location: str = Field(..., max_length=30)
    apartment: Optional[str] = Field(None, max_length=20)


class UserKYCUpdate(BaseModel):
    """تعديل من جهة العميل طالما أن الحالة ليست APPROVED."""
    id_type: Optional[IDType] = None
    id_number: Optional[str] = Field(None, max_length=50)
    id_expiry: Optional[date] = None
    nationality: Optional[str] = Field(None, max_length=50)
    country: Optional[str] = Field(None, max_length=30)
    city: Optional[str] = Field(None, max_length=20)
    location: Optional[str] = Field(None, max_length=30)
    apartment: Optional[str] = Field(None, max_length=20)


# ====== مراجعة الموظف ======

class KYCReviewDecision(BaseModel):
    """يستخدمه الموظف لاعتماد أو رفض KYC."""
    status: KYCStatus
    rejection_reason: Optional[str] = Field(
        None, description="سبب الرفض (إجباري إذا كانت الحالة REJECTED)"
    )


# ====== مخرجات ======

class UserKYCOut(BaseModel):
    kyc_id: int
    user_id: int
    id_type: IDType
    id_number: str

    # الصور قد تكون None في DRAFT
    id_front_image: Optional[str] = Field(None, max_length=255)
    id_back_image: Optional[str] = Field(None, max_length=255)
    selfie_image: Optional[str] = Field(None, max_length=255)

    status: KYCStatus
    verified_by: Optional[int] = None
    verified_at: Optional[datetime] = None
    created_at: datetime
    id_expiry: Optional[date] = None
    nationality: Optional[str] = None

    country: Optional[str] = None
    city: Optional[str] = None
    location: Optional[str] = None
    apartment: Optional[str] = None

    rejection_reason: Optional[str] = None

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    message: str