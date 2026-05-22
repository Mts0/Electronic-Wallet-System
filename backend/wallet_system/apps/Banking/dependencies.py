# Banking/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff.dependencies import require_permission
from . import models
from .services import BankingService


def require_staff_with_permission(permission_name: str):
    """
    Dependency جاهز لاستخدام صلاحيات staff
    مثال الاستخدام:
    staff = Depends(require_staff_with_permission("view_banks"))
    """
    return require_permission(permission_name)


def get_bank_or_404(
    bank_id: int,
    db: Session = Depends(get_session),
) -> models.LinkingBank:
    bank = BankingService.get_bank_by_id(db, bank_id)
    if not bank:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="البنك غير موجود",
        )
    return bank
