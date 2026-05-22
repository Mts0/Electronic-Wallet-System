# Banking/services.py

from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from . import models, schemas


class BankingService:
    """
    خدمات إدارة البنوك المرتبطة (linking_banks).
    تستخدم من لوحة الإدارة فقط (STAFF).
    """

    # ===== Getters =====

    @staticmethod
    def list_banks(
        db: Session,
        is_active: Optional[bool] = None,
    ) -> List[models.LinkingBank]:
        stmt = select(models.LinkingBank).order_by(models.LinkingBank.name.asc())
        if is_active is not None:
            stmt = stmt.where(models.LinkingBank.is_active == is_active)
        return list(db.scalars(stmt))

    @staticmethod
    def get_bank_by_id(
        db: Session, bank_id: int
    ) -> Optional[models.LinkingBank]:
        return db.get(models.LinkingBank, bank_id)

    @staticmethod
    def get_bank_by_code(
        db: Session, code: str
    ) -> Optional[models.LinkingBank]:
        return db.scalar(
            select(models.LinkingBank).where(models.LinkingBank.code == code)
        )

    # ===== Create / Update =====

    @staticmethod
    def create_bank(
        db: Session, payload: schemas.BankCreate
    ) -> models.LinkingBank:
        # التحقق من عدم تكرار الكود إن وجد
        if payload.code:
            existing = BankingService.get_bank_by_code(db, payload.code)
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="رمز البنك (code) مستخدم مسبقًا",
                )

        bank = models.LinkingBank(
            name=payload.name,
            code=payload.code,
            country=payload.country,
            is_active=payload.is_active,
        )
        db.add(bank)
        db.commit()
        db.refresh(bank)
        return bank

    @staticmethod
    def update_bank(
        db: Session,
        bank: models.LinkingBank,
        payload: schemas.BankUpdate,
    ) -> models.LinkingBank:
        if payload.name is not None:
            bank.name = payload.name

        if payload.code is not None:
            # لو تم تغيير الكود، تأكد ما يتكرر
            existing = BankingService.get_bank_by_code(db, payload.code)
            if existing and existing.bank_id != bank.bank_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="رمز البنك (code) مستخدم لبنك آخر",
                )
            bank.code = payload.code

        if payload.country is not None:
            bank.country = payload.country

        if payload.is_active is not None:
            bank.is_active = payload.is_active

        db.add(bank)
        db.commit()
        db.refresh(bank)
        return bank

    @staticmethod
    def set_bank_active(
        db: Session,
        bank: models.LinkingBank,
        is_active: bool,
    ) -> models.LinkingBank:
        bank.is_active = is_active
        db.add(bank)
        db.commit()
        db.refresh(bank)
        return bank
