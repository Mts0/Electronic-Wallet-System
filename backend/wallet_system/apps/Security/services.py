# apps/Security/services.py

from datetime import datetime
from typing import List, Optional, Dict, Any

from sqlalchemy.orm import Session
from sqlalchemy import select

from . import models, schemas


class SecurityService:
    """
    إدارة:
    - SecurityLog
    - AuditLog
    - AnalyticsLog
    - RealTimeEvent
    """

    # ===== SECURITY LOGS =====



    # ===== AUDIT LOGS =====

    @staticmethod
    def create_audit_log(
        db: Session,
        data: schemas.AuditLogCreate,
    ) -> models.AuditLog:
        log = models.AuditLog(
            user_id=data.user_id,
            changed_by=data.changed_by,
            action_type=data.action_type,
            old_data=data.old_data,
            new_data=data.new_data,
            created_at=datetime.utcnow(),
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        return log

    @staticmethod
    def list_audit_logs(
        db: Session,
        user_id: Optional[int] = None,
        changed_by: Optional[int] = None,
        action_type: Optional[str] = None,
        limit: int = 100,
    ) -> List[models.AuditLog]:
        stmt = select(models.AuditLog)

        if user_id is not None:
            stmt = stmt.where(models.AuditLog.user_id == user_id)
        if changed_by is not None:
            stmt = stmt.where(models.AuditLog.changed_by == changed_by)
        if action_type is not None:
            stmt = stmt.where(models.AuditLog.action_type == action_type)

        stmt = stmt.order_by(models.AuditLog.created_at.desc()).limit(limit)
        return list(db.scalars(stmt))

    @staticmethod
    def get_audit_log_by_id(
        db: Session,
        audit_id: int,
    ) -> Optional[models.AuditLog]:
        return db.get(models.AuditLog, audit_id)

    # ===== ANALYTICS LOGS =====



    # ===== REAL TIME EVENTS =====


