from datetime import datetime
from decimal import Decimal
from ..KYC.models import *
from sqlalchemy import (
    Column, Integer, String, Boolean, Date, DateTime,
    ForeignKey, DECIMAL,
    CheckConstraint, Index
)
from sqlalchemy.orm import relationship
from apps.core.database import Base


class User(Base):
    __tablename__ = "users"
    user_id = Column(Integer, primary_key=True, autoincrement=True)
    phone_number = Column(String(20), nullable=False)
    email = Column(String(100), nullable=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(150), nullable=False)
    date_of_birth = Column(Date, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    daily_limit = Column(DECIMAL(12, 2), default=Decimal("50000.00"), nullable=False)
    monthly_limit = Column(DECIMAL(12, 2), default=Decimal("150000.00"), nullable=False)
    user_type = Column(String(20), default="CUSTOMER", nullable=False)
    gender = Column(String(10), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    blocked_reason = Column(String, nullable=True)



    __table_args__ = (

        CheckConstraint(
            "user_type IN ('CUSTOMER','STAFF', 'SYSTEM')",
            name="ck_users_user_type"
        ),

        CheckConstraint(
            "gender IN ('MALE','FEMALE')",
            name="ck_users_gender"
        ),

        CheckConstraint("daily_limit >= 0", name="ck_users_daily_limit_non_negative"),
        CheckConstraint("monthly_limit >= 0", name="ck_users_monthly_limit_non_negative"),

        Index("idx_users_phone_number", "phone_number"),
        Index("idx_users_email", "email"),
        Index("idx_user_active", "is_active")
    )

    # العلاقات
    address = relationship("Address", back_populates="user", uselist=False, cascade="all, delete-orphan")
    password_resets = relationship("PasswordReset", back_populates="user", cascade="all, delete-orphan")
    verifications = relationship("Verification", back_populates="user", cascade="all, delete-orphan")
    kyc = relationship("UserKYC", back_populates="user", uselist=False)  # موجود عندك بملف ثاني
    sessions = relationship("UserSession", back_populates="user", cascade="all, delete-orphan")
    login_tries = relationship("LoginTry", back_populates="user", cascade="all, delete-orphan")
    devices = relationship("UserDevice", back_populates="user", cascade="all, delete-orphan")


class Address(Base):
    __tablename__ = "address"

    address_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
        unique=True
    )
    country = Column(String(30), nullable=True)
    city = Column(String(20), nullable=True)
    location = Column(String(30), nullable=False)
    apartment = Column(String(20), nullable=True)
    #محذوف country_code = Column(String(5), nullable=True)

    __table_args__ = (
        Index(
            "idx_userID_city_country",
            "user_id",
            "city",
            "country"
        ),
        Index("idx_address_user_id", "user_id"),
    )

    user = relationship("User", back_populates="address")


class PasswordReset(Base):
    __tablename__ = "password_reset"

    reset_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

    changed_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    method = Column(String(50), nullable=False)
    ip_address = Column(String(45), nullable=True)

    CheckConstraint(
        "method IN ('USER_CHANGE', 'FORGOT_PASSWORD', 'ADMIN_RESET')",
        name="ck_password_resets_method"
    )

    user = relationship("User", back_populates="password_resets")


class Verification(Base):
    __tablename__ = "verifications"

    verification_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    otp_code = Column(String(8), nullable=False)
    otp_expiry = Column(DateTime, nullable=False)
    is_used = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    device_info = Column(String, nullable=True)
    verification_type = Column(String(25), nullable=False)
    try_count = Column(Integer, default=0, nullable=False)

    __table_args__ = (
        CheckConstraint("try_count >= 0", name="ck_verifications_try_count_non_negative"),
        CheckConstraint("verification_type IN ('register','password_reset')", name="ck_verifi_type"),
        Index("idx_clean_expired_otp", "user_id", "is_used", "otp_expiry"),
    )

    user = relationship("User", back_populates="verifications")


class UserSession(Base):
    __tablename__ = "user_sessions"

    session_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    device_info = Column(String, nullable=True)
    ip_address = Column(String(45), nullable=True)
    token = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_access = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="sessions")


class LoginTry(Base):
    __tablename__ = "login_try"

    login_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=True)
    ip_address = Column(String(45), nullable=True)
    device_info = Column(String, nullable=True)
    status = Column(String(20), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    __table_args__ = (
        CheckConstraint("status IN ('SUCCESS','FAILED')", name="ck_status"),
    )

    user = relationship("User", back_populates="login_tries")


class UserDevice(Base):
    __tablename__ = "user_devices"

    device_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    user_type = Column(String(20), nullable=False)
    device_name = Column(String(100), nullable=False)
    device_type = Column(String(50), nullable=True)
    os = Column(String(50), nullable=False)
    browser = Column(String(50), nullable=True)
    fingerprint = Column(String(255), nullable=True)
    ip_address = Column(String(45), nullable=False)
    location = Column(String(100), nullable=True)
    jwt_token = Column(String(255), nullable=True)
    last_used = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    __table_args__ = (
        CheckConstraint(
            "user_type IN ('CUSTOMER','STAFF', 'SYSTEM')",
            name="ck_devices_user_type"
        ),
    )

    user = relationship("User", back_populates="devices")
