# apps/transactions/schemas.py

from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import Optional, List

from pydantic import BaseModel, condecimal, Field


# ===== Enums بناءً على الـ ERD =====

class TransactionType(str, Enum):
    TRANSFER = "TRANSFER"
    CASH_IN = "CASH_IN"
    MOBILE_TOPUP = "MOBILE_TOPUP"
    ATM_WITHDRAW = "ATM_WITHDRAW"
    EXCHANGE = "EXCHANGE"
    CASH_DEPOSIT = "CASH_DEPOSIT"
    INITIAL_FUNDING = "INITIAL_FUNDING"


class TransactionStatus(str, Enum):
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class FailedAction(str, Enum):
    TRANSFER = "TRANSFER"
    WITHDRAWAL = "WITHDRAWAL"
    EXCHANGE = "EXCHANGE"
    TOPUPS = "TOPUPS"
    # CASH_IN = "CASH_IN"


# ===== الأساسيات =====

class TransactionBase(BaseModel):
    amount: condecimal(max_digits=11, decimal_places=2) = Field(..., gt=0)
    fee: condecimal(max_digits=9, decimal_places=2) = Decimal("0.00")
    currency_id: int


class TransactionOut(BaseModel):
    transaction_id: int
    user_id: int
    currency_id: int
    amount: condecimal(max_digits=11, decimal_places=2)
    fee: condecimal(max_digits=9, decimal_places=2)
    type: TransactionType
    status: TransactionStatus
    notes: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ====== عمليات التحويل (TRANSFER) ======

class TransferCreate(BaseModel):
    from_account_id: int
    to_wallet_number: str = Field(..., min_length=1, max_length=100)
    # currency_id: int
    amount: condecimal(max_digits=11, decimal_places=2) = Field(..., gt=0)
    notes: Optional[str] = None


class CashInCreate(BaseModel):
    wallet_number: str = Field(..., min_length=1, max_length=100)
    currency_id: int
    amount: condecimal(max_digits=11, decimal_places=2) = Field(..., gt=0)
    notes: Optional[str] = None


class CashInOut(BaseModel):
    transaction: TransactionOut
    wallet_number: Optional[str] = None
    owner_name: Optional[str] = None

    class Config:
        from_attributes = True


class TransferOut(BaseModel):
    transaction: TransactionOut
    transfers_id: int
    to_wallet_number: Optional[str] = None
    to_user_name: Optional[str] = None

    class Config:
        from_attributes = True


# ====== عمليات الشحن (TOPUP) ======


class TopupCreate(BaseModel):
    amount: condecimal(max_digits=11, decimal_places=2) = Field(..., gt=0)
    phone_number: str = Field(..., min_length=9, max_length=15)
    package_code: Optional[str] = Field(None, max_length=20)
    notes: Optional[str] = Field(None, max_length=500)


class TopupOut(BaseModel):
    transaction: TransactionOut
    topup_id: int
    phone_number: str
    package_code: Optional[str]
    transaction_ref: str
    status_details: Optional[str]

    class Config:
        from_attributes = True


# ====== عمليات الصرف (EXCHANGE) ======

class ExchangeCreate(BaseModel):
    from_account_id: int
    to_account_id: int
    from_amount: condecimal(max_digits=11, decimal_places=2) = Field(..., gt=0)
    notes: Optional[str] = None


class ExchangeOut(BaseModel):
    transaction: TransactionOut
    exchange_id: int
    from_currency: int
    to_currency: int
    to_amount: condecimal(max_digits=11, decimal_places=2)
    exchange_rate: condecimal(max_digits=10, decimal_places=6)

    class Config:
        from_attributes = True


# ====== سحب من الصراف (ATM WITHDRAW) ======

class ATMWithdrawCreate(BaseModel):
    account_id: int
    amount: Decimal
    bank_id: int
    message: str | None = None


class ATMWithdrawOut(BaseModel):
    request_id: int
    user_id: int
    bank_id: int
    bank_name: Optional[str] = None
    bank_code: Optional[str] = None
    transaction_id: int
    code: str
    pin_code: str
    amount: condecimal(max_digits=8, decimal_places=2)
    currency: int
    status: str
    expires_at: datetime
    transaction_ref: str
    created_at: datetime

    class Config:
        from_attributes = True


# اضافة جديدة

class CashDepositCreate(BaseModel):
    wallet_number: str = Field(..., min_length=1, max_length=100)
    currency_id: int
    amount: condecimal(max_digits=11, decimal_places=2) = Field(..., gt=0)
    depositor_name: Optional[str] = Field(None, max_length=150)
    depositor_phone: Optional[str] = Field(None, max_length=20)
    notes: Optional[str] = None


class CashDepositOut(BaseModel):
    transaction: TransactionOut
    wallet_number: str
    owner_name: Optional[str] = None
    depositor_name: Optional[str] = None
    depositor_phone: Optional[str] = None
    reference_number: str





# ====== العمليات الفاشلة ======


# ====== استجابات عامة ======

class MessageResponse(BaseModel):
    message: str
