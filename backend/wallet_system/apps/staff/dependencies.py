from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from ..core.database import get_session
from ..auth.dependencies import get_current_staff_user  # يرجّع User من نوع STAFF
from ..auth import models as auth_models
from . import models
from .services import StaffService


def get_current_staff(
    db: Session = Depends(get_session),
    current_user: auth_models.User = Depends(get_current_staff_user),
) -> models.Staff:
    """
    يرجّع صف الموظف Staff المرتبط بالمستخدم الحالي (User.user_id)
    """
    staff = StaffService.get_staff_by_user_id(db, current_user.user_id)
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="هذا المستخدم ليس موظفًا في النظام",
        )

    if not staff.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="تم إلغاء نشاطك، تواصل مع الإدارة",
        )

    return staff


def require_permission(permission_name: str):
    """
    Dependency factory:
    يستخدم كالتالي في الراوتر:
    current_staff: Staff = Depends(require_permission("view_staff"))
    """

    def dependency(
        db: Session = Depends(get_session),
        staff: models.Staff = Depends(get_current_staff),
    ) -> models.Staff:
        perms = StaffService.get_staff_permissions(db, staff)
        if not any(p.name == permission_name for p in perms):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"لا توجد لديك الصلاحية المطلوبة: {permission_name}",
            )
        return staff

    return dependency
