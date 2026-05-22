# ExternalAPI/schemas.py

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum
from decimal import Decimal


class ServiceType(str, Enum):
    PAYMENT = "payment"
    IDENTITY_VERIFICATION = "identity_verification"
    SMS = "sms"
    EMAIL = "email"
    NOTIFICATION = "notification"
    FRAUD_DETECTION = "fraud_detection"
    EXCHANGE_RATE = "exchange_rate"
    OTHER = "other"


class AuthType(str, Enum):
    BEARER_TOKEN = "bearer_token"
    BASIC_AUTH = "basic_auth"
    API_KEY = "api_key"
    NONE = "none"


# ========= ExternalService =========

class ExternalServiceBase(BaseModel):
    name: str = Field(..., max_length=100)
    base_url: Optional[str] = Field(
        None, max_length=255, description="Base URL مثل https://api.provider.com"
    )
    auth_type: AuthType = AuthType.NONE
    api_key: Optional[str] = Field(
        None, max_length=255, description="API key أو token حسب نوع المصادقة"
    )
    secret_key: Optional[str] = Field(
        None, max_length=255, description="Secret key أو password مثل basic auth"
    )
    webhook_url: Optional[str] = Field(None, max_length=255)
    is_active: bool = True


class ExternalServiceCreate(ExternalServiceBase):
    name: str = Field(..., max_length=100)


class ExternalServiceUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    base_url: Optional[str] = Field(None, max_length=255)
    auth_type: Optional[AuthType] = None
    api_key: Optional[str] = Field(None, max_length=255)
    secret_key: Optional[str] = Field(None, max_length=255)
    webhook_url: Optional[str] = Field(None, max_length=255)
    is_active: Optional[bool] = None


class ExternalServiceResponse(ExternalServiceBase):
    service_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ========= ExternalServiceLog =========

class ExternalServiceLogBase(BaseModel):
    endpoint: Optional[str] = Field(
        None,
        description="المسار النسبي المستدعى مثل /v1/send أو /verify",
    )
    http_method: Optional[str] = Field(
        None,
        description="GET, POST, PUT,...",
        max_length=10,
    )
    response_status: Optional[int] = None
    execution_time: Optional[int] = Field(
        None, description="زمن التنفيذ بالمللي ثانية"
    )
    error_message: Optional[str] = None


class ExternalServiceLogResponse(ExternalServiceLogBase):
    log_id: int
    service_id: int
    created_at: datetime
    request_headers: Optional[Dict[str, Any]] = None
    request_body: Optional[Dict[str, Any]] = None
    response_headers: Optional[Dict[str, Any]] = None
    response_body: Optional[Dict[str, Any]] = None

    class Config:
        from_attributes = True


# ========= Test Call =========

class ServiceTestRequest(BaseModel):
    endpoint: Optional[str] = Field(
        None,
        description="المسار النسبي, لو None يتم استخدام base_url فقط",
    )
    method: str = Field(
        "GET", description="طريقة HTTP: GET / POST / PUT / DELETE ...", max_length=10
    )
    payload: Optional[Dict[str, Any]] = Field(
        None, description="جسم الطلب (JSON body) إن وجد"
    )
    headers: Optional[Dict[str, Any]] = Field(
        None, description="Headers إضافية اختيارية"
    )


class ServiceTestResponse(BaseModel):
    log: ExternalServiceLogResponse
