# SystemSetting/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff.dependencies import require_permission
from . import models
from .services import SystemSettingService


def require_staff_with_permission(permission_name: str):
    """
    نفس الباترون في باقي الموديولات.
    مثال:
        staff = Depends(require_staff_with_permission("manage_system_settings"))
    """
    return require_permission(permission_name)


def get_setting_or_404(
    setting_id: int,
    db: Session = Depends(get_session),
) -> models.SystemSetting:
    setting = SystemSettingService.get_setting_by_id(db, setting_id)
    if not setting:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الإعداد غير موجود",
        )
    return setting
