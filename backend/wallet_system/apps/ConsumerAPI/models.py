from sqlalchemy import (
    Column, Integer, String, Boolean, DateTime, Text, ForeignKey, JSON,
    CheckConstraint, UniqueConstraint, Index
)
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base


class APIConsumer(Base):
    __tablename__ = "api_consumers"

    consumer_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    api_key = Column(String(255), nullable=False,unique=True)
    allowed_ips = Column(Text, nullable=True)          # مثال: "1.1.1.1,2.2.2.2" أو CIDR
    allowed_endpoints = Column(JSON, nullable=True)    # قائمة/مصفوفة أو هيكل حسبك
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)



    access_logs = relationship(
        "APIAccessLog",
        back_populates="consumer",
        cascade="all, delete-orphan"
    )
    key_updates = relationship(
        "APIKeysUpdate",
        back_populates="consumer",
        cascade="all, delete-orphan"
    )


class APIAccessLog(Base):
    __tablename__ = "api_access_logs"

    log_id = Column(Integer, primary_key=True, autoincrement=True)
    consumer_id = Column(
        Integer,
        ForeignKey("api_consumers.consumer_id", ondelete="CASCADE"),
        nullable=False
    )

    endpoint = Column(String(255), nullable=False)
    http_method = Column(String(10), nullable=False)
    request_body = Column(JSON, nullable=True)
    response_status = Column(Integer, nullable=True)
    ip_address = Column(String(45), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)


    consumer = relationship("APIConsumer", back_populates="access_logs")


class APIKeysUpdate(Base):
    __tablename__ = "api_keys_update"

    au_id = Column(Integer, primary_key=True, autoincrement=True)
    consumer_id = Column(
        Integer,
        ForeignKey("api_consumers.consumer_id", ondelete="CASCADE"),
        nullable=False
    )
    old_api_key = Column(String(255), nullable=False)
    new_api_key = Column(String(255), nullable=False)
    changed_by = Column(
        Integer,
        ForeignKey("staff.staff_id", ondelete="SET NULL"),  # أو CASCADE حسب رغبتك
        nullable=False
    )
    changed_at = Column(DateTime, default=datetime.utcnow, nullable=False)


    changed_by_staff = relationship("Staff", back_populates="api_keys_updates")
    consumer = relationship("APIConsumer", back_populates="key_updates")

