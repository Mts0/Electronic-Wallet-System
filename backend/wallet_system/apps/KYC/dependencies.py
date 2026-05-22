# KYC/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user, get_current_kyc_verified_user
from ..staff.dependencies import require_permission, get_current_staff
from . import models
from .services import KYCService


def get_my_kyc(
        db: Session = Depends(get_session),
        current_user=Depends(get_current_active_user),
) -> models.UserKYC:
    kyc = KYCService.get_by_user_id(db, current_user.user_id)
    if not kyc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="لم يتم تقديم KYC بعد",
        )
    return kyc


def get_kyc_or_404(
        kyc_id: int,
        db: Session = Depends(get_session),
):
    kyc = KYCService.get_by_id(db, kyc_id)
    if not kyc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="سجل KYC غير موجود",
        )
    return kyc


def require_staff_with_permission(permission_name: str):
    """
    نفس الباترون في باقي الموديولات.
    """
    return require_permission(permission_name)
