# apps/wallets/schemas.py

from pydantic import BaseModel, Field, condecimal
from typing import Optional, List
from datetime import datetime
from enum import Enum


# ====== Enums (مستندة على ERD) ======

class WalletStatus(str, Enum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    CLOSED = "CLOSED"


class WalletAccountStatus(str, Enum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    CLOSED = "CLOSED"


# ====== Currency Schemas ======

class CurrencyBase(BaseModel):
    name: str = Field(..., max_length=50)
    symbol: str = Field(..., max_length=5)


class CurrencyOut(CurrencyBase):
    currency_id: int
    is_active: bool

    class Config:
        from_attributes = True


# ====== Wallet Account Schemas ======

class WalletAccountBase(BaseModel):
    status: WalletAccountStatus = WalletAccountStatus.ACTIVE


class WalletAccountCreate(BaseModel):
    currency_id: int
    initial_balance: condecimal(max_digits=11, decimal_places=2) = 0  # optional


class WalletAccountUpdateStatus(BaseModel):
    status: WalletAccountStatus


class WalletAccountOut(BaseModel):
    account_id: int
    wallet_id: int
    currency: CurrencyOut
    balance: condecimal(max_digits=11, decimal_places=2)
    status: WalletAccountStatus

    class Config:
        from_attributes = True


# ====== Wallet Schemas ======

class WalletOut(BaseModel):
    wallet_id: int
    user_id: int
    wallet_number: str
    is_system: bool
    status: WalletStatus
    created_at: Optional[datetime] = None
    closed_at: Optional[datetime] = None
    accounts: List[WalletAccountOut] = []

    class Config:
        from_attributes = True


# اضافات جديدة
class InitialFundingCreate(BaseModel):
    currency_id: int
    amount: condecimal(max_digits=11, decimal_places=2) = Field(..., gt=0)
    notes: Optional[str] = None


class InitialFundingOut(BaseModel):
    account_id: int
    wallet_id: int
    currency_id: int
    balance: condecimal(max_digits=12, decimal_places=2)
    amount: condecimal(max_digits=12, decimal_places=2)
    message: str


# ====== Generic Responses ======

class MessageResponse(BaseModel):
    message: str
