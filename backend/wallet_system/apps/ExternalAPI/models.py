from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base


class ExternalService(Base):
    __tablename__ = "external_services"

    service_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    base_url = Column(String(255))
    auth_type = Column(String(50))  # bearer_token, basic_auth, api_key, etc.
    api_key = Column(String(255))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


    # العلاقات
    logs = relationship("ExternalServiceLog", back_populates="service")



class ExternalServiceLog(Base):
    __tablename__ = "external_service_logs"

    log_id = Column(Integer, primary_key=True, autoincrement=True)
    service_id = Column(Integer, ForeignKey("external_services.service_id"))
    endpoint = Column(String(255))
    http_method = Column(String(10))
    request_body = Column(JSON)
    response_status = Column(Integer)
    response_body = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)

    # العلاقات
    service = relationship("ExternalService", back_populates="logs")