from __future__ import annotations

from decimal import Decimal
from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field


class AgentIntent(str, Enum):
    GET_WALLET_SUMMARY = "GET_WALLET_SUMMARY"
    LIST_TRANSACTIONS = "LIST_TRANSACTIONS"
    LIST_FAILED_TRANSACTIONS = "LIST_FAILED_TRANSACTIONS"
    TRANSFER_MONEY = "TRANSFER_MONEY"
    MOBILE_TOPUP = "MOBILE_TOPUP"
    EXCHANGE_MONEY = "EXCHANGE_MONEY"
    ATM_WITHDRAW_REQUEST = "ATM_WITHDRAW_REQUEST"
    GET_EXCHANGE_RATE = "GET_EXCHANGE_RATE"
    LIST_CURRENCIES = "LIST_CURRENCIES"
    ADD_FAVORITE_CONTACT = "ADD_FAVORITE_CONTACT"
    UNKNOWN = "UNKNOWN"


class AgentExecuteRequest(BaseModel):
    message: str = Field(..., min_length=2, description="طلب المستخدم بلغة طبيعية أو شبه طبيعية")
    intent: Optional[AgentIntent] = Field(None, description="يمكن تمريره مباشرة لتجاوز التحليل النصي")
    params: dict[str, Any] = Field(default_factory=dict, description="معاملات اختيارية تساعد الوكيل على التنفيذ")
    dry_run: bool = Field(False, description="إن كان True سيحلل الطلب بدون تنفيذ العملية")


class AgentPlan(BaseModel):
    intent: AgentIntent
    confidence: float = 0.0
    normalized_params: dict[str, Any] = Field(default_factory=dict)
    missing_fields: list[str] = Field(default_factory=list)
    user_message: str


class AgentExecuteResponse(BaseModel):
    ok: bool
    executed: bool
    plan: AgentPlan
    result: Optional[dict[str, Any]] = None


class AgentCapability(BaseModel):
    intent: AgentIntent
    description: str
    required_fields: list[str] = Field(default_factory=list)
    optional_fields: list[str] = Field(default_factory=list)


class TransferParams(BaseModel):
    from_account_id: int
    to_wallet_number: str
    amount: Decimal
    notes: Optional[str] = None


class TopupParams(BaseModel):
    amount: Decimal
    phone_number: str
    package_code: Optional[str] = None
    notes: Optional[str] = None


class ExchangeParams(BaseModel):
    from_account_id: int
    to_account_id: int
    from_amount: Decimal
    notes: Optional[str] = None


class ATMWithdrawParams(BaseModel):
    account_id: int
    amount: Decimal
    bank_id: int
    message: Optional[str] = None


class RateParams(BaseModel):
    base_currency: str
    target_currency: str


class FavoriteContactParams(BaseModel):
    name: str
    phone_number: str
