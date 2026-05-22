from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base


class FraudReport(Base):
    __tablename__ = "fraud_reports"

    report_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    subject = Column(String(100), nullable=False)
    transaction_reference = Column(String(100), nullable=True)
    description = Column(Text, nullable=False)

    status = Column(String(20), nullable=False, default="PENDING")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    resolved_by = Column(Integer, ForeignKey("staff.staff_id"), nullable=True)
    resolved_at = Column(DateTime, nullable=True)

    __table_args__ = (
        CheckConstraint(
            "status IN ('PENDING', 'INVESTIGATING', 'RESOLVED')",
            name="ck_fraud_status",
        ),
    )

    user = relationship("User")
    resolved_by_staff = relationship("Staff", foreign_keys=[resolved_by])