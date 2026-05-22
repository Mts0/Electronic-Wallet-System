# ExchangeRates/schemas.py

from datetime import datetime
from decimal import Decimal
from typing import Optional, List

from pydantic import BaseModel, Field, condecimal


class ExchangeRateBase(BaseModel):
    base_currency: str = Field(..., min_length=3, max_length=3)
    target_currency: str = Field(..., min_length=3, max_length=3)
    rate_value: condecimal(max_digits=18, decimal_places=6)


class ExchangeRateCreate(ExchangeRateBase):
    """
    تستخدم لإنشاء أو تحديث (upsert) سعر صرف لزوج عملات.
    """


class ExchangeRateUpdate(BaseModel):
    rate_value: Optional[condecimal(max_digits=18, decimal_places=6)] = None


class ExchangeRateOut(BaseModel):
    rate_id: int
    base_currency: str
    target_currency: str
    rate_value: condecimal(max_digits=18, decimal_places=6)
    updated_at: datetime

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    message: str
