from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base





class AuditLog(Base):
    __tablename__ = "audit_logs"

    audit_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    changed_by = Column(Integer, ForeignKey("staff.staff_id"), nullable=False)
    action_type = Column(String(50))      # UPDATE_PHONE, DELETE_ACCOUNT, ......
    old_data = Column(JSON)
    new_data = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
    changed_by_staff = relationship("Staff")







