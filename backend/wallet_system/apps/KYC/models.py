from sqlalchemy import (
    Column, Integer, String, DateTime, Date,
    ForeignKey, CheckConstraint,
)
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base


class UserKYC(Base):
    __tablename__ = "user_kyc"

    kyc_id = Column(Integer, primary_key=True, autoincrement=True)

    user_id = Column(
        Integer,
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
        unique=True
    )

    id_type = Column(String(50), nullable=False)
    id_number = Column(String(50), nullable=False, unique=True)

    id_front_image = Column(String(255), nullable=True)
    id_back_image = Column(String(255), nullable=True)
    selfie_image = Column(String(255), nullable=True)
    status = Column(String(20), default="DRAFT", nullable=False)
    verified_by = Column(Integer, nullable=True)  # لاحقًا FK إلى staff إذا عندك جدول staff
    verified_at = Column(DateTime, nullable=True)  # خليه NULL إلا إذا تم التحقق فعلاً
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    id_expiry = Column(Date, nullable=False)
    nationality = Column(String(50), nullable=False)
    rejection_reason = Column(String, nullable=True)

    __table_args__ = (

        CheckConstraint("id_type IN ('NATIONAL_ID','PASSPORT')", name="ck_id_type"),

        CheckConstraint(
            "status IN ('PENDING','APPROVED','REJECTED','DRAFT')",
            name="ck_user_kyc_status"
        ),

    )

    user = relationship("User", back_populates="kyc")



    @property
    def country(self):
        return self.user.address.country if self.user and self.user.address else None

    @property
    def city(self):
        return self.user.address.city if self.user and self.user.address else None

    @property
    def location(self):
        return self.user.address.location if self.user and self.user.address else None

    @property
    def apartment(self):
        return self.user.address.apartment if self.user and self.user.address else None
