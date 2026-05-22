# apps/fraud/schemas.py

from datetime import datetime
from typing import Optional
from enum import Enum

from pydantic import BaseModel, Field


class FraudStatus(str, Enum):
    PENDING = "PENDING"
    INVESTIGATING = "INVESTIGATING"
    RESOLVED = "RESOLVED"


# ===== طلب إنشاء بلاغ من العميل =====

class FraudReportCreate(BaseModel):
    subject: str = Field(..., max_length=100, description="موضوع البلاغ")
    transaction_reference: Optional[str] = Field(
        None,
        max_length=100,
        description="رقم العملية المرجعي إن وجد",
    )
    description: str = Field(..., description="شرح لما حدث في بلاغ الاحتيال")


# ===== تحديث الحالة من جهة الموظف =====

class FraudReportStatusUpdate(BaseModel):
    status: FraudStatus = Field(..., description="الحالة الجديدة للبلاغ")


# ===== مخرجات عامة =====

class FraudReportOut(BaseModel):
    report_id: int
    user_id: int
    subject: str
    transaction_reference: Optional[str] = None
    description: str
    status: FraudStatus
    created_at: datetime
    resolved_by: Optional[int] = None
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    message: str