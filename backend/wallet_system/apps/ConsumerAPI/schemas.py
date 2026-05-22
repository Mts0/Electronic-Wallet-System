from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# ========= Consumers =========

class APIConsumerBase(BaseModel):
    name: str = Field(..., max_length=100)
    allowed_ips: Optional[str] = None  # قائمة IPs نصية مثلاً مفصولة بفواصل
    allowed_endpoints: Optional[dict] = None  # JSON: مثلاً {"paths": ["/v1/pay", "/v1/balance"]}
    is_active: bool = True


class APIConsumerCreate(APIConsumerBase):
    pass


class APIConsumerUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    allowed_ips: Optional[str] = None
    allowed_endpoints: Optional[dict] = None
    is_active: Optional[bool] = None


class APIConsumerOut(BaseModel):
    consumer_id: int
    name: str
    api_key: str
    allowed_ips: Optional[str]
    allowed_endpoints: Optional[dict]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ========= Access Logs =========

class APIAccessLogOut(BaseModel):
    log_id: int
    consumer_id: int
    endpoint: str
    http_method: str
    request_body: Optional[dict]
    response_status: Optional[int]
    ip_address: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# ========= API Key Rotation =========

class APIKeyRotateRequest(BaseModel):
    reason: Optional[str] = Field(
        None, description="سبب تدوير / تغيير مفتاح الـ API (اختياري)"
    )


class APIKeysUpdateOut(BaseModel):
    au_id: int
    consumer_id: int
    old_api_key: str
    new_api_key: str
    changed_by: int
    changed_at: datetime

    class Config:
        from_attributes = True


# ========= Generic =========

class MessageResponse(BaseModel):
    message: str
