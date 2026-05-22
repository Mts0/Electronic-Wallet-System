from sqlalchemy import Column, Integer, String, DateTime,DECIMAL
from datetime import datetime
from ..core.database import Base


class ExchangeRate(Base):
    __tablename__ = "exchange_rates"

    rate_id = Column(Integer, primary_key=True, autoincrement=True)
    base_currency = Column(String(5), nullable=False)
    target_currency = Column(String(5), nullable=False)
    rate_value = Column(DECIMAL(18, 6), nullable=False)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow)
