from datetime import date, datetime
from typing import Optional, List
from decimal import Decimal
from pydantic import BaseModel, Field, condecimal
from enum import Enum


# ========= ENUMS =========

class LimitType(str, Enum):
    DAILY = "daily_limit"
    MONTHLY = "monthly_limit"


# ========= STAFF =========

class StaffBase(BaseModel):
    user_id: int
    monthly_salary: condecimal(max_digits=10, decimal_places=2)
    hire_date: date
    university_major: str = Field(..., max_length=100)
    is_active: bool = True


class StaffCreate(StaffBase):
    pass


class StaffUpdate(BaseModel):
    monthly_salary: Optional[condecimal(max_digits=10, decimal_places=2)] = None
    university_major: Optional[str] = Field(None, max_length=100)
    is_active: Optional[bool] = None


class StaffOut(BaseModel):
    staff_id: int
    user_id: int
    monthly_salary: Optional[Decimal]
    hire_date: date
    university_major: str
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


# ========= ROLES & PERMISSIONS =========

class RoleBase(BaseModel):
    name: str = Field(..., max_length=50)


class RoleCreate(RoleBase):
    pass


class RoleUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=50)


class RoleOut(BaseModel):
    role_id: int
    name: str
    created_at: datetime

    class Config:
        from_attributes = True


class PermissionBase(BaseModel):
    name: str = Field(..., max_length=100)
    description: Optional[str] = None


class PermissionCreate(PermissionBase):
    pass


class PermissionOut(BaseModel):
    permission_id: int
    name: str
    description: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class StaffRoleAssign(BaseModel):
    staff_id: int
    role_id: int


class RolePermissionAssign(BaseModel):
    role_id: int
    permission_id: int


# ========= USER LIMITS =========

class UserLimitChange(BaseModel):
    user_id: int
    type: LimitType
    new_limit: condecimal(max_digits=9, decimal_places=2)


class UserLimitOut(BaseModel):
    limit_id: int
    user_id: int
    old_limit: Optional[Decimal]
    new_limit: Optional[Decimal]
    type: str
    changed_by: int
    changed_at: datetime

    class Config:
        from_attributes = True


# ========= /me =========

class StaffMeOut(BaseModel):
    staff: StaffOut
    roles: List[RoleOut]
    permissions: List[PermissionOut]


# ========= Generic =========

class MessageResponse(BaseModel):
    message: str
