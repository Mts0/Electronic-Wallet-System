# Banking/routes.py

from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff import models as staff_models
from . import schemas, models
from .services import BankingService
from .dependencies import (
    require_staff_with_permission,
    get_bank_or_404,
)

router = APIRouter(prefix="/banking", tags=["Banking / Linking Banks"])


# ====== قائمة البنوك ======

@router.get(
    "/banks",
    response_model=List[schemas.BankOut],
)
def list_banks(
    is_active: bool | None = None,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_banks")
    ),
    
):
    banks = BankingService.list_banks(db, is_active=is_active)
    return banks


# ====== إنشاء بنك جديد ======

@router.post(
    "/banks",
    response_model=schemas.BankOut,
    status_code=status.HTTP_201_CREATED,
)
def create_bank(
    payload: schemas.BankCreate,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_banks")
    ),
):
    bank = BankingService.create_bank(db, payload)
    return bank


# ====== جلب بنك واحد ======

@router.get(
    "/banks/{bank_id}",
    response_model=schemas.BankOut,
)
def get_bank(
    bank: models.LinkingBank = Depends(get_bank_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_banks")
    ),
):
    return bank


# ====== تعديل بيانات بنك ======

@router.patch(
    "/banks/{bank_id}",
    response_model=schemas.BankOut,
)
def update_bank(
    payload: schemas.BankUpdate,
    db: Session = Depends(get_session),
    bank: models.LinkingBank = Depends(get_bank_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_banks")
    ),
):
    bank = BankingService.update_bank(db, bank, payload)
    return bank


# ====== تفعيل بنك ======

@router.post(
    "/banks/{bank_id}/activate",
    response_model=schemas.BankOut,
)
def activate_bank(
    db: Session = Depends(get_session),
    bank: models.LinkingBank = Depends(get_bank_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_banks")
    ),
):
    bank = BankingService.set_bank_active(db, bank, True)
    return bank


# ====== إيقاف بنك ======

@router.post(
    "/banks/{bank_id}/deactivate",
    response_model=schemas.BankOut,
)
def deactivate_bank(
    db: Session = Depends(get_session),
    bank: models.LinkingBank = Depends(get_bank_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_banks")
    ),
):
    bank = BankingService.set_bank_active(db, bank, False)
    return bank
