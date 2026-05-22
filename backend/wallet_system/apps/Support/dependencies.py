# Support/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user
from ..staff.dependencies import require_permission
from . import models
from .services import CallCenterService, NotificationService


def require_staff_with_permission(permission_name: str):
    """
    زي باقي الموديولات:
    staff = Depends(require_staff_with_permission("manage_call_center"))
    """
    return require_permission(permission_name)


def get_ticket_or_404(
    ticket_id: int,
    db: Session = Depends(get_session),
) -> models.CallCenter:
    ticket = CallCenterService.get_ticket_by_id(db, ticket_id)
    if not ticket:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="التذكرة غير موجودة",
        )
    return ticket




def get_notification_or_404(
    notification_id: int,
    db: Session = Depends(get_session),
) -> models.Notification:
    notification = NotificationService.get_notification_by_id(db, notification_id)
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الإشعار غير موجود",
        )
    return notification


def get_my_notification_or_404(
    notification_id: int,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_active_user),
) -> models.Notification:
    notification = NotificationService.get_notification_by_id(db, notification_id)
    if not notification or notification.user_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الإشعار غير موجود أو لا يتبع لك",
        )
    return notification
