from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    Text,
    ForeignKey,
    CheckConstraint,
    Index,
    DECIMAL
)
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    transaction_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    currency_id = Column(Integer, ForeignKey("currencies.currency_id"), nullable=False)
    # مهم جداً: لا نستخدم Float في الأموال لتفادي أخطاء الكسور
    amount = Column(DECIMAL(11, 2), nullable=False)
    fee = Column(DECIMAL(9, 2), default=0)
    type = Column(String(20), nullable=False)
    status = Column(String(20), default="PENDING", nullable=False)
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint("amount >= 0", name="ck_transaction_amount"),
        CheckConstraint(
            "type IN ('INITIAL_FUNDING', 'TRANSFER', 'CASH_IN', 'CASH_DEPOSIT', 'MOBILE_TOPUP', 'ATM_WITHDRAW', "
            "'EXCHANGE')",
            name="ck_transaction_type"
        ),
        CheckConstraint("status IN ('PENDING', 'COMPLETED', 'FAILED')", name="ck_transaction_status"),
        Index('idx_user_recent_transactions', 'user_id', 'created_at', 'status'),
    )

    user = relationship("User")
    currency = relationship("Currency")
    topup = relationship("TransactionTopup", back_populates="transaction", uselist=False)
    transfer = relationship("TransactionTransfer", back_populates="transaction", uselist=False)
    exchange = relationship("TransactionExchange", back_populates="transaction", uselist=False)
    atm_withdraw = relationship("ATMWithdrawRequest", back_populates="transaction", uselist=False)
    cash_deposit = relationship(
        "TransactionCashDeposit",
        back_populates="transaction",
        uselist=False,
        cascade="all, delete-orphan",
    )

class TransactionTopup(Base):
    __tablename__ = "transaction_topups"

    topup_id = Column(Integer, primary_key=True, autoincrement=True)
    transaction_id = Column(Integer, ForeignKey("transactions.transaction_id", ondelete="CASCADE"), unique=True,
                            nullable=False)
    phone_number = Column(String(15), nullable=False)
    package_code = Column(String(20))
    transaction_ref = Column(String(100), unique=True, nullable=False)
    status_details = Column(Text)

    transaction = relationship("Transaction", back_populates="topup")


class TransactionTransfer(Base):
    __tablename__ = "transaction_transfers"

    transfers_id = Column(Integer, primary_key=True, autoincrement=True)
    transaction_id = Column(Integer, ForeignKey("transactions.transaction_id", ondelete="CASCADE"), unique=True,
                            nullable=False)
    from_wallet = Column(Integer, ForeignKey("wallets.wallet_id"), nullable=False)
    to_wallet = Column(Integer, ForeignKey("wallets.wallet_id"), nullable=False)



    transaction = relationship("Transaction", back_populates="transfer")
    from_wallet_rel = relationship("Wallet", foreign_keys=[from_wallet])
    to_wallet_rel = relationship("Wallet", foreign_keys=[to_wallet])


class TransactionExchange(Base):
    __tablename__ = "transaction_exchange"

    exchange_id = Column(Integer, primary_key=True, autoincrement=True)
    transaction_id = Column(Integer, ForeignKey("transactions.transaction_id", ondelete="CASCADE"), unique=True,
                            nullable=False)
    from_currency = Column(Integer, ForeignKey("currencies.currency_id"), nullable=False)
    to_currency = Column(Integer, ForeignKey("currencies.currency_id"), nullable=False)
    to_amount = Column(DECIMAL(11, 2), nullable=False)
    exchange_rate = Column(DECIMAL(10, 6))

    transaction = relationship("Transaction", back_populates="exchange")
    from_currency_rel = relationship("Currency", foreign_keys=[from_currency])
    to_currency_rel = relationship("Currency", foreign_keys=[to_currency])


class ATMWithdrawRequest(Base):
    __tablename__ = "atm_withdraw_requests"

    request_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    bank_id = Column(Integer, ForeignKey("linking_banks.bank_id"), nullable=False)
    transaction_id = Column(Integer, ForeignKey("transactions.transaction_id", ondelete="CASCADE"), unique=True,
                            nullable=False)
    code = Column(String(11), unique=True, nullable=False)
    amount = Column(DECIMAL(8, 2), nullable=False)
    currency = Column(Integer, ForeignKey("currencies.currency_id"), nullable=False)
    pin_code = Column(String(10), nullable=False)
    message = Column(Text)
    status = Column(String(20), default="PENDING", nullable=False)
    expires_at = Column(DateTime, nullable=False)
    transaction_ref = Column(String(100), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        CheckConstraint("amount > 0", name="ck_atm_amount"),
        CheckConstraint("status IN ('PENDING', 'COMPLETED', 'FAILED', 'EXPIRED')", name="ck_atm_status"),
    )

    user = relationship("User")
    bank = relationship("LinkingBank")
    transaction = relationship("Transaction", back_populates="atm_withdraw")
    currency_rel = relationship("Currency", foreign_keys=[currency])


class TransactionCashDeposit(Base):
    __tablename__ = "transaction_cash_deposits"

    cash_deposit_id = Column(Integer, primary_key=True, autoincrement=True)
    transaction_id = Column(
        Integer,
        ForeignKey("transactions.transaction_id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    wallet_id = Column(
        Integer,
        ForeignKey("wallets.wallet_id"),
        nullable=False,
    )
    staff_id = Column(
        Integer,
        ForeignKey("staff.staff_id"),
        nullable=False,
    )
    depositor_name = Column(String(150), nullable=True)
    depositor_phone = Column(String(20), nullable=True)
    reference_number = Column(String(100), nullable=False, unique=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    transaction = relationship(
        "Transaction",
        back_populates="cash_deposit",
    )