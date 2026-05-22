# apps/fraud/services.py

from datetime import datetime
from typing import List, Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from . import models, schemas


class FraudReportService:
    """
    منطق عمل بلاغات الاحتيال:
    - العميل ينشئ البلاغ
    - العميل يعرض بلاغاته
    - الموظف يستعرض كل البلاغات ويحدث الحالة
    """

    # ===== استعلامات عامة =====

    @staticmethod
    def list_user_reports(
        db: Session,
        user_id: int,
    ) -> List[models.FraudReport]:
        stmt = (
            select(models.FraudReport)
            .where(models.FraudReport.user_id == user_id)
            .order_by(models.FraudReport.created_at.desc())
        )
        return list(db.scalars(stmt))

    @staticmethod
    def get_user_report(
        db: Session,
        report_id: int,
        user_id: int,
    ) -> Optional[models.FraudReport]:
        stmt = (
            select(models.FraudReport)
            .where(
                models.FraudReport.report_id == report_id,
                models.FraudReport.user_id == user_id,
            )
        )
        return db.scalar(stmt)

    @staticmethod
    def get_by_id(
        db: Session,
        report_id: int,
    ) -> Optional[models.FraudReport]:
        return db.get(models.FraudReport, report_id)

    @staticmethod
    def list_all(
        db: Session,
        status_filter: Optional[schemas.FraudStatus] = None,
        limit: int = 100,
    ) -> List[models.FraudReport]:
        stmt = select(models.FraudReport).order_by(
            models.FraudReport.created_at.desc()
        )

        if status_filter:
            stmt = stmt.where(
                models.FraudReport.status == status_filter.value
            )

        stmt = stmt.limit(limit)
        return list(db.scalars(stmt))

    # ===== من جهة العميل =====

    @staticmethod
    def create_report(
        db: Session,
        user_id: int,
        data: schemas.FraudReportCreate,
    ) -> models.FraudReport:
        report = models.FraudReport(
            user_id=user_id,
            subject=data.subject,
            transaction_reference=data.transaction_reference,
            description=data.description,
            status=schemas.FraudStatus.PENDING.value,
            created_at=datetime.utcnow(),
            resolved_by=None,
            resolved_at=None,
        )

        db.add(report)
        db.commit()
        db.refresh(report)
        return report

    # ===== من جهة الموظف =====

    @staticmethod
    def update_status(
        db: Session,
        report: models.FraudReport,
        new_status: schemas.FraudStatus,
        staff_id: int,
    ) -> models.FraudReport:
        """
        - أي تغيير للحالة يتم تسجيل آخر موظف تعامل مع البلاغ
        - إذا أصبحت الحالة RESOLVED يتم تعبئة resolved_at
        """
        report.status = new_status.value
        report.resolved_by = staff_id

        if new_status == schemas.FraudStatus.RESOLVED:
            report.resolved_at = datetime.utcnow()
        else:
            report.resolved_at = None

        db.add(report)
        db.commit()
        db.refresh(report)
        return report