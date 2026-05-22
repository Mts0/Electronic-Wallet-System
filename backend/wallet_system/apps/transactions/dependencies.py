# apps/transactions/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user,get_current_kyc_verified_user
from . import models


def get_user_transaction_by_id(
    transaction_id: int,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
) -> models.Transaction:
    tx = db.scalar(
        select(models.Transaction).where(
            models.Transaction.transaction_id == transaction_id,
            models.Transaction.user_id == current_user.user_id,
        )
    )
    if not tx:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="العملية غير موجودة أو لا تتبع لهذا المستخدم",
        )
    return tx
