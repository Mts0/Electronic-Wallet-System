# SystemSetting/schemas.py

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# ========== SYSTEM SETTINGS ==========

class SystemSettingBase(BaseModel):
    setting_name: str = Field(..., max_length=100)
    setting_value: str
    description: Optional[str] = None
    is_public: bool = False


class SystemSettingCreate(SystemSettingBase):
    """
    يستخدم لإنشاء إعداد جديد من طرف الموظف.
    """
    pass


class SystemSettingUpdate(BaseModel):
    """
    تحديث إعداد موجود، مع تسجيل التغيير في جدول settings_update.
    """
    setting_name: Optional[str] = Field(None, max_length=100)
    setting_value: Optional[str] = None
    description: Optional[str] = None
    is_public: Optional[bool] = None


class SystemSettingOut(BaseModel):
    setting_id: int
    setting_name: str
    setting_value: str
    description: Optional[str]
    is_public: bool
    updated_by: int
    updated_at: datetime

    class Config:
        from_attributes = True


class SystemSettingPublicOut(BaseModel):
    """
    مخرجات الإعدادات العامة (لواجهة العميل مثلاً).
    ما فيها معلومات عن الموظف.
    """
    setting_name: str
    setting_value: str
    description: Optional[str]

    class Config:
        from_attributes = True


# ========== SETTINGS UPDATE HISTORY ==========

class SettingsUpdateOut(BaseModel):
    updateSett_id: int
    setting_id: int
    old_value: Optional[str]
    new_value: Optional[str]
    changed_by: int
    changed_at: datetime

    class Config:
        from_attributes = True


# ========== Generic ==========

class MessageResponse(BaseModel):
    message: str
