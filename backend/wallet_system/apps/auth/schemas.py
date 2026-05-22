from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import date, datetime
from enum import Enum


# ===== Enums =====

class Gender(str, Enum):
    MALE = "MALE"
    FEMALE = "FEMALE"


class UserType(str, Enum):
    CUSTOMER = "CUSTOMER"
    STAFF = "STAFF"
    SYSTEM = "SYSTEM"


class VerificationType(str, Enum):
    REGISTER = "register"
    PASSWORD_RESET = "password_reset"


# ===== User Schemas =====

class UserBase(BaseModel):
    full_name: str = Field(..., max_length=150)
    phone_number: str = Field(..., max_length=20)
    email: Optional[EmailStr] = None
    gender: Gender
    date_of_birth: date


class UserCreate(UserBase):
    password: str = Field(..., min_length=6, max_length=128)

    @validator("phone_number")
    def phone_not_empty(cls, v: str):
        if not v:
            raise ValueError("رقم الهاتف مطلوب")
        return v


class UserLogin(BaseModel):
    phone_number: Optional[str] = None
    email: Optional[EmailStr] = None
    password: str

    @validator("password")
    def password_not_empty(cls, v: str):
        if not v:
            raise ValueError("كلمة المرور مطلوبة")
        return v

    @validator("phone_number", "email", always=True)
    def at_least_one_identifier(cls, v, values):
        if not v and not values.get("phone_number") and not values.get("email"):
            raise ValueError("يجب إدخال رقم الهاتف أو البريد الإلكتروني")
        return v


class UserResponse(BaseModel):
    user_id: int
    full_name: str
    phone_number: str
    email: Optional[EmailStr]
    user_type: UserType
    is_verified: bool
    is_active: bool
    blocked_reason: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# ===== Token / Auth Schemas =====

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    refresh_token: Optional[str] = None
    user: UserResponse


# ===== OTP / Verification Schemas =====

class OTPRequest(BaseModel):
    phone_number: str
    verification_type: VerificationType = VerificationType.REGISTER

    @validator("phone_number")
    def phone_not_empty(cls, v: str):
        if not v:
            raise ValueError("رقم الهاتف مطلوب")
        return v


class OTPVerify(BaseModel):
    phone_number: str
    otp_code: str
    verification_type: VerificationType = VerificationType.REGISTER

    @validator("otp_code")
    def otp_not_empty(cls, v: str):
        if not v:
            raise ValueError("رمز التحقق مطلوب")
        return v


# ===== Password Schemas =====

class PasswordChange(BaseModel):
    current_password: str
    new_password: str

    @validator("new_password")
    def new_password_not_same(cls, v, values):
        if "current_password" in values and v == values["current_password"]:
            raise ValueError("كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية")
        return v


class PasswordResetRequest(BaseModel):
    phone_number: Optional[str] = None
    email: Optional[EmailStr] = None

    @validator("phone_number", "email", always=True)
    def at_least_one(cls, v, values):
        if not v and not values.get("phone_number") and not values.get("email"):
            raise ValueError("أدخل رقم الهاتف أو البريد الإلكتروني")
        return v


class PasswordResetConfirm(BaseModel):
    phone_number: Optional[str] = None
    email: Optional[EmailStr] = None
    otp_code: str
    new_password: str

    @validator("otp_code")
    def otp_not_empty(cls, v: str):
        if not v:
            raise ValueError("رمز التحقق مطلوب")
        return v

    @validator("new_password")
    def strong_password(cls, v: str):
        if len(v) < 6:
            raise ValueError("كلمة المرور يجب أن تكون 6 أحرف على الأقل")
        return v

    @validator("phone_number", "email", always=True)
    def at_least_one(cls, v, values):
        if not v and not values.get("phone_number") and not values.get("email"):
            raise ValueError("أدخل رقم الهاتف أو البريد الإلكتروني")
        return v


# ===== Session / Device Schemas (للاستخدام لاحقًا لو حبيت) =====

class SessionResponse(BaseModel):
    session_id: int
    ip_address: Optional[str]
    device_info: Optional[str]
    is_active: bool
    created_at: datetime
    last_access: Optional[datetime]

    class Config:
        from_attributes = True


# ===== Generic Response Schemas =====

class MessageResponse(BaseModel):
    message: str


class ErrorResponse(BaseModel):
    detail: str
