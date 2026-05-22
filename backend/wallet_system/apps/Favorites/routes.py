# Favorites/routes.py

from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user ,get_current_kyc_verified_user
from . import schemas, models
from .services import FavoritesService
from .dependencies import (
    get_my_favorite_contact,
    get_my_favorite_transfer,
    get_my_favorite_internet,
)

router = APIRouter(prefix="/favorites", tags=["favorites"])


# ========= CONTACTS =========

@router.get(
    "/contacts",
    response_model=List[schemas.FavoriteContactOut],
)
def list_my_favorite_contacts(
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    return FavoritesService.list_contacts_for_user(db, current_user.user_id)


@router.post(
    "/contacts",
    response_model=schemas.FavoriteContactOut,
    status_code=status.HTTP_201_CREATED,
)
def create_my_favorite_contact(
    payload: schemas.FavoriteContactCreate,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    contact = FavoritesService.create_contact_for_user(
        db, current_user.user_id, payload
    )
    return contact


@router.get(
    "/contacts/{fc_id}",
    response_model=schemas.FavoriteContactOut,
)
def get_my_favorite_contact_details(
    contact: models.FavoriteContact = Depends(get_my_favorite_contact),
):
    return contact


@router.patch(
    "/contacts/{fc_id}",
    response_model=schemas.FavoriteContactOut,
)
def update_my_favorite_contact(
    payload: schemas.FavoriteContactUpdate,
    db: Session = Depends(get_session),
    contact: models.FavoriteContact = Depends(get_my_favorite_contact),
):
    contact = FavoritesService.update_contact(db, contact, payload)
    return contact


@router.delete(
    "/contacts/{fc_id}",
    response_model=schemas.MessageResponse,
)
def delete_my_favorite_contact(
    db: Session = Depends(get_session),
    contact: models.FavoriteContact = Depends(get_my_favorite_contact),
):
    FavoritesService.delete_contact(db, contact)
    return schemas.MessageResponse(message="تم حذف جهة الاتصال من المفضلة بنجاح")


# ========= TRANSFERS =========

@router.get(
    "/transfers",
    response_model=List[schemas.FavoriteTransferOut],
)
def list_my_favorite_transfers(
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    return FavoritesService.list_transfers_for_user(db, current_user.user_id)


@router.post(
    "/transfers",
    response_model=schemas.FavoriteTransferOut,
    status_code=status.HTTP_201_CREATED,
)
def create_my_favorite_transfer(
    payload: schemas.FavoriteTransferCreate,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    transfer = FavoritesService.create_transfer_for_user(
        db, current_user.user_id, payload
    )
    return transfer


@router.get(
    "/transfers/{ft_id}",
    response_model=schemas.FavoriteTransferOut,
)
def get_my_favorite_transfer_details(
    transfer: models.FavoriteTransfer = Depends(get_my_favorite_transfer),
):
    return transfer


@router.patch(
    "/transfers/{ft_id}",
    response_model=schemas.FavoriteTransferOut,
)
def update_my_favorite_transfer(
    payload: schemas.FavoriteTransferUpdate,
    db: Session = Depends(get_session),
    transfer: models.FavoriteTransfer = Depends(get_my_favorite_transfer),
):
    transfer = FavoritesService.update_transfer(db, transfer, payload)
    return transfer


@router.delete(
    "/transfers/{ft_id}",
    response_model=schemas.MessageResponse,
)
def delete_my_favorite_transfer(
    db: Session = Depends(get_session),
    transfer: models.FavoriteTransfer = Depends(get_my_favorite_transfer),
):
    FavoritesService.delete_transfer(db, transfer)
    return schemas.MessageResponse(message="تم حذف التحويل المفضل بنجاح")


# ========= INTERNET =========

@router.get(
    "/internet",
    response_model=List[schemas.FavoriteInternetOut],
)
def list_my_favorite_internet(
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    return FavoritesService.list_internet_for_user(db, current_user.user_id)


@router.post(
    "/internet",
    response_model=schemas.FavoriteInternetOut,
    status_code=status.HTTP_201_CREATED,
)
def create_my_favorite_internet(
    payload: schemas.FavoriteInternetCreate,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    fav = FavoritesService.create_internet_for_user(
        db, current_user.user_id, payload
    )
    return fav


@router.get(
    "/internet/{fi_id}",
    response_model=schemas.FavoriteInternetOut,
)
def get_my_favorite_internet_details(
    fav: models.FavoriteInternet = Depends(get_my_favorite_internet),
):
    return fav


@router.patch(
    "/internet/{fi_id}",
    response_model=schemas.FavoriteInternetOut,
)
def update_my_favorite_internet(
    payload: schemas.FavoriteInternetUpdate,
    db: Session = Depends(get_session),
    fav: models.FavoriteInternet = Depends(get_my_favorite_internet),
):
    fav = FavoritesService.update_internet(db, fav, payload)
    return fav


@router.delete(
    "/internet/{fi_id}",
    response_model=schemas.MessageResponse,
)
def delete_my_favorite_internet(
    db: Session = Depends(get_session),
    fav: models.FavoriteInternet = Depends(get_my_favorite_internet),
):
    FavoritesService.delete_internet(db, fav)
    return schemas.MessageResponse(message="تم حذف الخدمة المفضلة بنجاح")
