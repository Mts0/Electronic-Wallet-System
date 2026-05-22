# Support/routes.py

from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user
from ..staff import models as staff_models
from . import schemas, models
from .services import CallCenterService, NotificationService
from .dependencies import (
    require_staff_with_permission,
    get_ticket_or_404,
    get_notification_or_404,
    get_my_notification_or_404,
)

router = APIRouter(prefix="/support", tags=["Support"])






# ========== CALL CENTER – جزء الموظفين (STAFF) ==========

@router.get(
    "/tickets",
    response_model=List[schemas.CallCenterOut],
)
def list_tickets(
    user_id: Optional[int] = Query(None),
    assigned_to: Optional[int] = Query(None),
    status_filter: Optional[str] = Query(None, alias="status"),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_call_center_tickets")
    ),
):
    tickets = CallCenterService.list_tickets(
        db=db,
        user_id=user_id,
        assigned_to=assigned_to,
        status=status_filter,
        limit=limit,
    )
    return tickets


@router.get(
    "/tickets/{ticket_id}",
    response_model=schemas.CallCenterOut,
)
def get_ticket_details(
    ticket: models.CallCenter = Depends(get_ticket_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_call_center_tickets")
    ),
):
    return ticket


@router.post(
    "/tickets",
    response_model=schemas.CallCenterOut,
    status_code=status.HTTP_201_CREATED,
)
def create_ticket(
    payload: schemas.CallCenterCreate,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_call_center_tickets")
    ),
):
    ticket = CallCenterService.create_ticket(db, payload)
    return ticket


@router.patch(
    "/tickets/{ticket_id}/status",
    response_model=schemas.CallCenterOut,
)
def update_ticket_status(
    payload: schemas.CallCenterUpdateStatus,
    db: Session = Depends(get_session),
    ticket: models.CallCenter = Depends(get_ticket_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_call_center_tickets")
    ),
):
    updated = CallCenterService.update_status(db, ticket, payload.status)
    return updated


@router.patch(
    "/tickets/{ticket_id}/assign",
    response_model=schemas.CallCenterOut,
)
def reassign_ticket(
    payload: schemas.CallCenterReassign,
    db: Session = Depends(get_session),
    ticket: models.CallCenter = Depends(get_ticket_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_call_center_tickets")
    ),
):
    updated = CallCenterService.reassign_ticket(db, ticket, payload.assigned_to)
    return updated


# ========== NOTIFICATIONS – جزء العميل ==========

@router.get(
    "/notifications/me",
    response_model=List[schemas.NotificationOut],
)
def list_my_notifications(
    is_read: Optional[bool] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    current_user=Depends(get_current_active_user),
):
    notifs = NotificationService.list_notifications_for_user(
        db=db,
        user_id=current_user.user_id,
        is_read=is_read,
        limit=limit,
    )
    return notifs


@router.post(
    "/notifications/me/{notification_id}/read",
    response_model=schemas.NotificationOut,
)
def mark_my_notification_as_read(
    db: Session = Depends(get_session),
    notification: models.Notification = Depends(get_my_notification_or_404),
):
    updated = NotificationService.mark_as_read(db, notification)
    return updated


# ========== NOTIFICATIONS – جزء الموظفين ==========

@router.get(
    "/notifications",
    response_model=List[schemas.NotificationOut],
)
def list_notifications(
    user_id: Optional[int] = Query(None),
    is_read: Optional[bool] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_notifications")
    ),
):
    notifs = NotificationService.list_notifications(
        db=db,
        user_id=user_id,
        is_read=is_read,
        limit=limit,
    )
    return notifs


@router.get(
    "/notifications/{notification_id}",
    response_model=schemas.NotificationOut,
)
def get_notification_details(
    notification: models.Notification = Depends(get_notification_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_notifications")
    ),
):
    return notification


@router.post(
    "/notifications",
    response_model=schemas.NotificationOut,
    status_code=status.HTTP_201_CREATED,
)
def create_notification(
    payload: schemas.NotificationCreate,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_notifications")
    ),
):
    notif = NotificationService.create_notification(db, payload)
    return notif
