# Favorites/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user , get_current_kyc_verified_user
from . import models
from .services import FavoritesService


def get_my_favorite_contact(
    fc_id: int,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
) -> models.FavoriteContact:
    contact = FavoritesService.get_contact_for_user(db, fc_id, current_user.user_id)
    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="جهة الاتصال غير موجودة أو لا تتبع لك",
        )
    return contact


def get_my_favorite_transfer(
    ft_id: int,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
) -> models.FavoriteTransfer:
    transfer = FavoritesService.get_transfer_for_user(db, ft_id, current_user.user_id)
    if not transfer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="التحويل المفضل غير موجود أو لا يتبع لك",
        )
    return transfer


def get_my_favorite_internet(
    fi_id: int,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
) -> models.FavoriteInternet:
    fav = FavoritesService.get_internet_for_user(db, fi_id, current_user.user_id)
    if not fav:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الخدمة المفضلة غير موجودة أو لا تتبع لك",
        )
    return fav
