# apps/Security/schemas.py

from datetime import datetime
from typing import Optional, Dict, Any

from pydantic import BaseModel, Field


# ========== SECURITY LOGS ==========






# ========== AUDIT LOGS ==========

class AuditLogCreate(BaseModel):
    user_id: int
    changed_by: int
    action_type: str = Field(..., max_length=50)
    old_data: Optional[Dict[str, Any]] = None
    new_data: Optional[Dict[str, Any]] = None


class AuditLogOut(BaseModel):
    audit_id: int
    user_id: int
    changed_by: int
    action_type: Optional[str]
    old_data: Optional[Dict[str, Any]]
    new_data: Optional[Dict[str, Any]]
    created_at: datetime

    class Config:
        from_attributes = True


# ========== ANALYTICS LOGS ==========







# ========== REAL TIME EVENTS ==========







# ========== Generic ==========

class MessageResponse(BaseModel):
    message: str
