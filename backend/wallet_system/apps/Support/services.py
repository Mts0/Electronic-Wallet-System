# Support/services.py

from datetime import datetime
from typing import List, Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from . import models, schemas
from fastapi import HTTPException
from ..wallets import models as wallet_models
from ..staff import models as staff_models

class CallCenterService:
    """
    منطق تذاكر مركز الاتصال (call_center)
    """

    @staticmethod
    def create_ticket(
            db: Session,
            payload: schemas.CallCenterCreate,
    ) -> models.CallCenter:
        wallet = db.scalar(
            select(wallet_models.Wallet).where(
                wallet_models.Wallet.wallet_number == payload.wallet_number
            )
        )
        if not wallet:
            raise HTTPException(status_code=404, detail="رقم المحفظة غير موجود")

        assigned_staff = db.scalar(
            select(staff_models.Staff).where(
                staff_models.Staff.staff_id == payload.assigned_to
            )
        )
        if not assigned_staff:
            raise HTTPException(status_code=404, detail="الموظف المسؤول غير موجود")

        ticket = models.CallCenter(
            user_id=wallet.user_id,
            subject=payload.subject,
            message=payload.message,
            status="OPEN",
            assigned_to=payload.assigned_to,
            created_at=datetime.utcnow(),
        )
        db.add(ticket)
        db.commit()
        db.refresh(ticket)
        return ticket

    @staticmethod
    def get_ticket_by_id(
        db: Session,
        ticket_id: int,
    ) -> Optional[models.CallCenter]:
        return db.get(models.CallCenter, ticket_id)

    @staticmethod
    def list_tickets(
        db: Session,
        user_id: Optional[int] = None,
        assigned_to: Optional[int] = None,
        status: Optional[str] = None,
        limit: int = 100,
    ) -> List[models.CallCenter]:
        stmt = select(models.CallCenter)

        if user_id is not None:
            stmt = stmt.where(models.CallCenter.user_id == user_id)

        if assigned_to is not None:
            stmt = stmt.where(models.CallCenter.assigned_to == assigned_to)

        if status is not None:
            stmt = stmt.where(models.CallCenter.status == status)

        stmt = stmt.order_by(models.CallCenter.created_at.desc()).limit(limit)
        return list(db.scalars(stmt))



    @staticmethod
    def update_status(
        db: Session,
        ticket: models.CallCenter,
        status_value: str,
    ) -> models.CallCenter:
        ticket.status = status_value
        db.add(ticket)
        db.commit()
        db.refresh(ticket)
        return ticket

    @staticmethod
    def reassign_ticket(
        db: Session,
        ticket: models.CallCenter,
        staff_id: int,
    ) -> models.CallCenter:
        ticket.assigned_to = staff_id
        db.add(ticket)
        db.commit()
        db.refresh(ticket)
        return ticket


class NotificationService:
    """
    منطق الإشعارات (notifications)
    """

    @staticmethod
    def create_notification(
        db: Session,
        payload: schemas.NotificationCreate,
    ) -> models.Notification:
        notification = models.Notification(
            user_id=payload.user_id,
            title=payload.title,
            message=payload.message,
            is_read=False,
            created_at=datetime.utcnow(),
        )
        db.add(notification)
        db.commit()
        db.refresh(notification)
        return notification

    @staticmethod
    def get_notification_by_id(
        db: Session,
        notification_id: int,
    ) -> Optional[models.Notification]:
        return db.get(models.Notification, notification_id)

    @staticmethod
    def list_notifications_for_user(
        db: Session,
        user_id: int,
        is_read: Optional[bool] = None,
        limit: int = 100,
    ) -> List[models.Notification]:
        stmt = select(models.Notification).where(
            models.Notification.user_id == user_id
        )
        if is_read is not None:
            stmt = stmt.where(models.Notification.is_read == is_read)

        stmt = stmt.order_by(models.Notification.created_at.desc()).limit(limit)
        return list(db.scalars(stmt))

    @staticmethod
    def list_notifications(
        db: Session,
        user_id: Optional[int] = None,
        is_read: Optional[bool] = None,
        limit: int = 100,
    ) -> List[models.Notification]:
        stmt = select(models.Notification)
        if user_id is not None:
            stmt = stmt.where(models.Notification.user_id == user_id)
        if is_read is not None:
            stmt = stmt.where(models.Notification.is_read == is_read)

        stmt = stmt.order_by(models.Notification.created_at.desc()).limit(limit)
        return list(db.scalars(stmt))

    @staticmethod
    def mark_as_read(
        db: Session,
        notification: models.Notification,
    ) -> models.Notification:
        notification.is_read = True
        db.add(notification)
        db.commit()
        db.refresh(notification)
        return notification
