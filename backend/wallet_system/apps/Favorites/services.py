# Favorites/services.py

from typing import List, Optional

from sqlalchemy.orm import Session
from sqlalchemy import select

from . import models, schemas


class FavoritesService:
    """
    خدمة إدارة المفضلات الخاصة بالمستخدم:
    - favorite_contacts
    - favorite_transfers
    - favorite_internet
    """

    # ============ CONTACTS ============

    @staticmethod
    def list_contacts_for_user(db: Session, user_id: int) -> List[models.FavoriteContact]:
        stmt = (
            select(models.FavoriteContact)
            .where(models.FavoriteContact.user_id == user_id)
            .order_by(models.FavoriteContact.created_at.desc())
        )
        return list(db.scalars(stmt))

    @staticmethod
    def get_contact_for_user(
        db: Session, fc_id: int, user_id: int
    ) -> Optional[models.FavoriteContact]:
        stmt = (
            select(models.FavoriteContact)
            .where(
                models.FavoriteContact.fc_id == fc_id,
                models.FavoriteContact.user_id == user_id,
            )
        )
        return db.scalar(stmt)

    @staticmethod
    def create_contact_for_user(
        db: Session, user_id: int, payload: schemas.FavoriteContactCreate
    ) -> models.FavoriteContact:
        contact = models.FavoriteContact(
            user_id=user_id,
            name=payload.name,
            phone_number=payload.phone_number,
        )
        db.add(contact)
        db.commit()
        db.refresh(contact)
        return contact

    @staticmethod
    def update_contact(
        db: Session,
        contact: models.FavoriteContact,
        payload: schemas.FavoriteContactUpdate,
    ) -> models.FavoriteContact:
        if payload.name is not None:
            contact.name = payload.name
        if payload.phone_number is not None:
            contact.phone_number = payload.phone_number

        db.add(contact)
        db.commit()
        db.refresh(contact)
        return contact

    @staticmethod
    def delete_contact(db: Session, contact: models.FavoriteContact) -> None:
        db.delete(contact)
        db.commit()

    # ============ TRANSFERS ============

    @staticmethod
    def list_transfers_for_user(
        db: Session, user_id: int
    ) -> List[models.FavoriteTransfer]:
        stmt = (
            select(models.FavoriteTransfer)
            .where(models.FavoriteTransfer.user_id == user_id)
            .order_by(models.FavoriteTransfer.created_at.desc())
        )
        return list(db.scalars(stmt))

    @staticmethod
    def get_transfer_for_user(
        db: Session, ft_id: int, user_id: int
    ) -> Optional[models.FavoriteTransfer]:
        stmt = (
            select(models.FavoriteTransfer)
            .where(
                models.FavoriteTransfer.ft_id == ft_id,
                models.FavoriteTransfer.user_id == user_id,
            )
        )
        return db.scalar(stmt)

    @staticmethod
    def create_transfer_for_user(
        db: Session, user_id: int, payload: schemas.FavoriteTransferCreate
    ) -> models.FavoriteTransfer:
        transfer = models.FavoriteTransfer(
            user_id=user_id,
            wallet_number=payload.wallet_number,
            name=payload.name
        )
        db.add(transfer)
        db.commit()
        db.refresh(transfer)
        return transfer

    @staticmethod
    def update_transfer(
        db: Session,
        transfer: models.FavoriteTransfer,
        payload: schemas.FavoriteTransferUpdate,
    ) -> models.FavoriteTransfer:
        if payload.wallet_number is not None:
            transfer.wallet_number = payload.wallet_number
        if payload.notes is not None:
            transfer.notes = payload.notes

        db.add(transfer)
        db.commit()
        db.refresh(transfer)
        return transfer

    @staticmethod
    def delete_transfer(db: Session, transfer: models.FavoriteTransfer) -> None:
        db.delete(transfer)
        db.commit()

    # ============ INTERNET ============

    @staticmethod
    def list_internet_for_user(
        db: Session, user_id: int
    ) -> List[models.FavoriteInternet]:
        stmt = (
            select(models.FavoriteInternet)
            .where(models.FavoriteInternet.user_id == user_id)
            .order_by(models.FavoriteInternet.created_at.desc())
        )
        return list(db.scalars(stmt))

    @staticmethod
    def get_internet_for_user(
        db: Session, fi_id: int, user_id: int
    ) -> Optional[models.FavoriteInternet]:
        stmt = (
            select(models.FavoriteInternet)
            .where(
                models.FavoriteInternet.fi_id == fi_id,
                models.FavoriteInternet.user_id == user_id,
            )
        )
        return db.scalar(stmt)

    @staticmethod
    def create_internet_for_user(
        db: Session, user_id: int, payload: schemas.FavoriteInternetCreate
    ) -> models.FavoriteInternet:
        fav = models.FavoriteInternet(
            user_id=user_id,
            name=payload.name,
            subcription_number=payload.subcription_number,
        )
        db.add(fav)
        db.commit()
        db.refresh(fav)
        return fav

    @staticmethod
    def update_internet(
        db: Session,
        fav: models.FavoriteInternet,
        payload: schemas.FavoriteInternetUpdate,
    ) -> models.FavoriteInternet:
        if payload.name is not None:
            fav.name = payload.name

        db.add(fav)
        db.commit()
        db.refresh(fav)
        return fav

    @staticmethod
    def delete_internet(db: Session, fav: models.FavoriteInternet) -> None:
        db.delete(fav)
        db.commit()
