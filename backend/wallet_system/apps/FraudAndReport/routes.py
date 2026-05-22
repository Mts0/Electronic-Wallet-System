# apps/fraud/routes.py

from typing import List, Optional

from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_kyc_verified_user
from ..staff import models as staff_models
from . import schemas, models
from .services import FraudReportService
from .dependencies import (
    get_my_fraud_report,
    get_fraud_report_or_404,
    require_staff_with_permission,
)

router = APIRouter(prefix="/fraud-reports", tags=["Fraud Reports"])


# ========= جزء العميل (اللي يبلغ عن احتيال) =========

@router.get(
    "/me",
    response_model=List[schemas.FraudReportOut],
)
def list_my_fraud_reports(
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    reports = FraudReportService.list_user_reports(db, current_user.user_id)
    return reports


@router.post(
    "/me",
    response_model=schemas.FraudReportOut,
    status_code=status.HTTP_201_CREATED,
)
def create_fraud_report(
    payload: schemas.FraudReportCreate,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    """
    العميل يرسل بلاغ احتيال جديد.
    """
    report = FraudReportService.create_report(
        db=db,
        user_id=current_user.user_id,
        data=payload,
    )
    return report


@router.get(
    "/me/{report_id}",
    response_model=schemas.FraudReportOut,
)
def get_my_fraud_report_details(
    report: models.FraudReport = Depends(get_my_fraud_report),
):
    return report


# ========= جزء الموظف (STAFF) =========

@router.get(
    "",
    response_model=List[schemas.FraudReportOut],
)
def list_all_fraud_reports(
    status_filter: Optional[schemas.FraudStatus] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_fraud_reports")
    ),
):
    reports = FraudReportService.list_all(
        db=db,
        status_filter=status_filter,
        limit=limit,
    )
    return reports


@router.get(
    "/{report_id}",
    response_model=schemas.FraudReportOut,
)
def get_fraud_report_details(
    report: models.FraudReport = Depends(get_fraud_report_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_fraud_reports")
    ),
):
    return report


@router.post(
    "/{report_id}/status",
    response_model=schemas.FraudReportOut,
)
def update_fraud_report_status(
    payload: schemas.FraudReportStatusUpdate,
    db: Session = Depends(get_session),
    report: models.FraudReport = Depends(get_fraud_report_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_fraud_reports")
    ),
):
    """
    الموظف يغيّر حالة البلاغ:
    - PENDING
    - INVESTIGATING
    - RESOLVED
    """
    updated = FraudReportService.update_status(
        db=db,
        report=report,
        new_status=payload.status,
        staff_id=staff.staff_id,
    )
    return updated