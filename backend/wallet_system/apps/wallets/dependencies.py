# apps/wallets/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user
from . import models
from .services import WalletService


def get_current_user_wallet(
    db: Session = Depends(get_session),
    current_user=Depends(get_current_active_user),
) -> models.Wallet:
    """
    يرجع محفظة المستخدم الحالية،
    أو ينشئها لو مش موجودة
    """
    wallet = WalletService.get_or_create_wallet_for_user(db, current_user.user_id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="لم يتم العثور على محفظة للمستخدم",
        )
    return wallet


def get_current_user_wallet_account(
    account_id: int,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_active_user),
) -> models.WalletAccount:
    """
    يرجع حساب محفظة (WalletAccount) لمستخدم معين ويتأكد إنها تابعة له
    """
    account = WalletService.get_wallet_account_for_user(db, account_id, current_user.user_id)
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الحساب غير موجود أو لا يتبع لهذا المستخدم",
        )
    return account
