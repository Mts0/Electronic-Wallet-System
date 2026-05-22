from sqlalchemy import Column, Integer, String, Boolean,DECIMAL,DateTime, ForeignKey, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base




class Wallet(Base):
    __tablename__ = "wallets"

    wallet_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), unique=True, nullable=False)
    wallet_number = Column(String(100), unique=True, nullable=False)
    is_system = Column(Boolean, default=False)
    status = Column(String(10), default="ACTIVE")
    created_at = Column(DateTime, default=datetime.utcnow)
    closed_at = Column(DateTime)

    __table_args__ = (
        CheckConstraint("status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')", name="ck_wallet_status"),
    )

    accounts = relationship(
        "WalletAccount",
        back_populates="wallet",
        order_by="WalletAccount.currency_id",
    )


class WalletAccount(Base):
    __tablename__ = "wallet_accounts"

    account_id = Column(Integer, primary_key=True, autoincrement=True)
    wallet_id = Column(Integer, ForeignKey("wallets.wallet_id"), nullable=False)
    currency_id = Column(Integer, ForeignKey("currencies.currency_id"), nullable=False)
    balance = Column(DECIMAL(11,2), default=0.00)
    status = Column(String(10), default="ACTIVE")

    __table_args__ = (
        CheckConstraint("status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')", name="ck_account_status"),
        UniqueConstraint('wallet_id', 'currency_id', name='idx_unique_wallet_currency'),
    )

    wallet = relationship("Wallet", back_populates="accounts")
    currency = relationship("Currency")


class Currency(Base):
    __tablename__ = "currencies"

    currency_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), nullable=False)
    symbol = Column(String(5), nullable=False)
    is_active = Column(Boolean, default=True)
