# apps/fraud/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_kyc_verified_user
from ..staff.dependencies import require_permission
from . import models
from .services import FraudReportService


def get_my_fraud_report(
    report_id: int,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
) -> models.FraudReport:
    report = FraudReportService.get_user_report(
        db=db,
        report_id=report_id,
        user_id=current_user.user_id,
    )
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="البلاغ غير موجود أو لا يتبع لك",
        )
    return report


def get_fraud_report_or_404(
    report_id: int,
    db: Session = Depends(get_session),
) -> models.FraudReport:
    report = FraudReportService.get_by_id(db, report_id)
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="بلاغ الاحتيال غير موجود",
        )
    return report


def require_staff_with_permission(permission_name: str):
    """
    مثال:
    staff = Depends(require_staff_with_permission("view_fraud_reports"))
    """
    return require_permission(permission_name)