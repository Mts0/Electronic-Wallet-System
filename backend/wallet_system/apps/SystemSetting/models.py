from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base


class SystemSetting(Base):
    __tablename__ = "system_settings"

    setting_id = Column(Integer, primary_key=True, autoincrement=True)
    setting_name = Column(String(100), unique=True, nullable=False)
    setting_value = Column(Text, nullable=False)
    description = Column(Text)
    is_public = Column(Boolean, default=False)
    updated_by = Column(Integer, ForeignKey("staff.staff_id"), nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow)

    updates = relationship("SettingsUpdate", back_populates="setting")
    updated_by_staff = relationship("Staff")


class SettingsUpdate(Base):
    __tablename__ = "settings_update"

    updateSett_id = Column(Integer, primary_key=True, autoincrement=True)
    setting_id = Column(Integer, ForeignKey("system_settings.setting_id"), nullable=False)
    old_value = Column(Text)
    new_value = Column(Text)
    changed_by = Column(Integer, ForeignKey("staff.staff_id"), nullable=False)
    changed_at = Column(DateTime, default=datetime.utcnow)

    setting = relationship("SystemSetting", back_populates="updates")
    changed_by_staff = relationship("Staff")