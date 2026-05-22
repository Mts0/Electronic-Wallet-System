# ExchangeRates/services.py

from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select, and_

from . import models, schemas


class ExchangeRateService:
    """
    خدمة لإدارة أسعار الصرف:
    - إضافة/تحديث (upsert) سعر صرف
    - جلب سعر صرف لزوج عملات
    - قائمة الأسعار
    """

    # ========= Getters =========

    @staticmethod
    def list_rates(
        db: Session,
        base_currency: Optional[str] = None,
        target_currency: Optional[str] = None,
    ) -> List[models.ExchangeRate]:
        stmt = select(models.ExchangeRate)

        if base_currency:
            stmt = stmt.where(models.ExchangeRate.base_currency == base_currency.upper())

        if target_currency:
            stmt = stmt.where(
                models.ExchangeRate.target_currency == target_currency.upper()
            )

        stmt = stmt.order_by(
            models.ExchangeRate.base_currency.asc(),
            models.ExchangeRate.target_currency.asc(),
        )
        return list(db.scalars(stmt))

    @staticmethod
    def get_rate_by_id(
        db: Session, rate_id: int
    ) -> Optional[models.ExchangeRate]:
        return db.get(models.ExchangeRate, rate_id)

    @staticmethod
    def get_rate_by_pair(
        db: Session, base_currency: str, target_currency: str
    ) -> Optional[models.ExchangeRate]:
        base = base_currency.upper()
        target = target_currency.upper()
        return db.scalar(
            select(models.ExchangeRate).where(
                and_(
                    models.ExchangeRate.base_currency == base,
                    models.ExchangeRate.target_currency == target,
                )
            )
        )

    # ========= Upsert =========

    @classmethod
    def upsert_rate(
        cls,
        db: Session,
        payload: schemas.ExchangeRateCreate,
    ) -> models.ExchangeRate:
        base = payload.base_currency.upper()
        target = payload.target_currency.upper()

        if base == target:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="لا يمكن تعريف سعر صرف لنفس العملة",
            )

        existing = cls.get_rate_by_pair(db, base, target)

        if existing:
            # تحديث
            existing.rate_value = Decimal(payload.rate_value)
            existing.updated_at = datetime.utcnow()
            db.add(existing)
            db.commit()
            db.refresh(existing)
            return existing

        # إنشاء جديد
        rate = models.ExchangeRate(
            base_currency=base,
            target_currency=target,
            rate_value=Decimal(payload.rate_value),
            updated_at=datetime.utcnow(),
        )
        db.add(rate)
        db.commit()
        db.refresh(rate)
        return rate

    @classmethod
    def update_rate_value(
        cls,
        db: Session,
        rate: models.ExchangeRate,
        payload: schemas.ExchangeRateUpdate,
    ) -> models.ExchangeRate:
        if payload.rate_value is not None:
            rate.rate_value = Decimal(payload.rate_value)
        rate.updated_at = datetime.utcnow()
        db.add(rate)
        db.commit()
        db.refresh(rate)
        return rate

    # ========= Helper لاستخدامه من موديولات ثانية =========

    @classmethod
    def get_rate_value(
        cls,
        db: Session,
        base_currency: str,
        target_currency: str,
    ) -> Decimal:
        """
        يرجع قيمة سعر الصرف (rate_value) أو يرفع 404 لو غير موجود.
        """
        rate = cls.get_rate_by_pair(db, base_currency, target_currency)
        if not rate:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="سعر الصرف لهذا الزوج غير موجود",
            )
        return Decimal(rate.rate_value)
