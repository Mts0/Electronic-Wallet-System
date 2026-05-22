# Banking/schemas.py

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class BankBase(BaseModel):
    name: str = Field(..., max_length=50)
    code: Optional[str] = Field(None, max_length=20)
    country: Optional[str] = Field(None, max_length=3)
    is_active: bool = True


class BankCreate(BankBase):
    name: str = Field(..., max_length=50)



class BankUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=50)
    code: Optional[str] = Field(None, max_length=20)
    country: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None


class BankOut(BaseModel):
    bank_id: int
    name: str
    code: Optional[str]
    country: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    message: str
