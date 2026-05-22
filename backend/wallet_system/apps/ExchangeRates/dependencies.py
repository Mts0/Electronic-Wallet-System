# ExchangeRates/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff.dependencies import require_permission
from . import models
from .services import ExchangeRateService


def require_staff_with_permission(permission_name: str):
    """
    نفس نمط الموديولات السابقة:
    مثال الاستخدام في الراوتر:
    staff = Depends(require_staff_with_permission("manage_exchange_rates"))
    """
    return require_permission(permission_name)


def get_rate_or_404(
    rate_id: int,
    db: Session = Depends(get_session),
) -> models.ExchangeRate:
    rate = ExchangeRateService.get_rate_by_id(db, rate_id)
    if not rate:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="سعر الصرف غير موجود",
        )
    return rate
