# ExchangeRates/routes.py

from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff import models as staff_models
from . import schemas, models
from .services import ExchangeRateService
from .dependencies import require_staff_with_permission, get_rate_or_404

router = APIRouter(prefix="/exchange-rates", tags=["Exchange Rates"])


# ====== قراءة عامة (ممكن تستخدمها من أي جهة) ======

@router.get(
    "",
    response_model=List[schemas.ExchangeRateOut],
)
def list_exchange_rates(
    base_currency: Optional[str] = Query(None, min_length=3, max_length=3),
    target_currency: Optional[str] = Query(None, min_length=3, max_length=3),
    db: Session = Depends(get_session),
):
    rates = ExchangeRateService.list_rates(
        db=db,
        base_currency=base_currency,
        target_currency=target_currency,
    )
    return rates


@router.get(
    "/pair",
    response_model=schemas.ExchangeRateOut,
)
def get_rate_by_pair(
    base_currency: str = Query(..., min_length=3, max_length=3),
    target_currency: str = Query(..., min_length=3, max_length=3),
    db: Session = Depends(get_session),
):
    rate = ExchangeRateService.get_rate_by_pair(db, base_currency, target_currency)
    if not rate:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="سعر الصرف لهذا الزوج غير موجود",
        )
    return rate


@router.get(
    "/{rate_id}",
    response_model=schemas.ExchangeRateOut,
)
def get_rate(
    rate: models.ExchangeRate = Depends(get_rate_or_404),
):
    return rate


# ====== إدارة الأسعار (STAFF) ======

@router.post(
    "",
    response_model=schemas.ExchangeRateOut,
    status_code=status.HTTP_201_CREATED,
)
def upsert_exchange_rate(
    payload: schemas.ExchangeRateCreate,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_exchange_rates")
    ),
):
    """
    لو الزوج موجود → يعدل القيمة.
    لو غير موجود → ينشئ سجل جديد.
    """
    rate = ExchangeRateService.upsert_rate(db, payload)
    return rate


@router.patch(
    "/{rate_id}",
    response_model=schemas.ExchangeRateOut,
)
def update_exchange_rate(
    payload: schemas.ExchangeRateUpdate,
    db: Session = Depends(get_session),
    rate: models.ExchangeRate = Depends(get_rate_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_exchange_rates")
    ),
):
    rate = ExchangeRateService.update_rate_value(db, rate, payload)
    return rate
