from sqlalchemy import (
    Column, Integer, String, Boolean,
    UniqueConstraint, CheckConstraint, Index
)
from sqlalchemy.orm import relationship
from ..core.database import Base


class LinkingBank(Base):
    __tablename__ = "linking_banks"

    bank_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), nullable=False)
    code = Column(String(20), nullable=True)
    country = Column(String(50), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)


    atm_withdrawals = relationship(
        "ATMWithdrawRequest",
        back_populates="bank",
        cascade="all, delete-orphan"
    )
