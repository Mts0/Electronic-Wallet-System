# apps/KYC/services.py

from datetime import datetime
from typing import Optional, List

import os
import uuid
from pathlib import Path

from fastapi import HTTPException, status, UploadFile
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import select
from apps.auth import models as auth_models
from . import models, schemas
from apps.auth.models import Address

class KYCService:
    """
    منطق KYC:
    - تقديم / تحديث KYC من العميل (بيانات فقط -> DRAFT)
    - رفع الصور في endpoint منفصل (ثم تتحول إلى PENDING)
    - مراجعة واعتماد/رفض من الموظف
    """

    # ===== Getters عامة =====

    @staticmethod
    def get_by_user_id(db: Session, user_id: int) -> Optional[models.UserKYC]:
        return db.scalar(
            select(models.UserKYC)
            .options(joinedload(models.UserKYC.user).joinedload(auth_models.User.address))
            .where(models.UserKYC.user_id == user_id)
        )

    @staticmethod
    def get_by_id(db: Session, kyc_id: int) -> Optional[models.UserKYC]:
        return db.scalar(
            select(models.UserKYC)
            .options(joinedload(models.UserKYC.user).joinedload(auth_models.User.address))
            .where(models.UserKYC.kyc_id == kyc_id)
        )

    @staticmethod
    def list_all(
            db: Session,
            status_filter: Optional[schemas.KYCStatus] = None,
            limit: int = 100,
    ) -> List[models.UserKYC]:
        stmt = (
            select(models.UserKYC)
            .options(joinedload(models.UserKYC.user).joinedload(auth_models.User.address))
            .order_by(models.UserKYC.created_at.desc())
        )

        if status_filter:
            stmt = stmt.where(models.UserKYC.status == status_filter.value)
        else:
            stmt = stmt.where(models.UserKYC.status != schemas.KYCStatus.DRAFT.value)

        stmt = stmt.limit(limit)
        return list(db.scalars(stmt))

    # ===== من جهة العميل (البيانات فقط) =====

    @classmethod
    def submit_kyc_for_user(
        cls,
        db: Session,
        user_id: int,
        payload: schemas.UserKYCDraftCreate,  #  بيانات فقط
    ) -> models.UserKYC:
        """
        - لو ما عنده KYC → ننشئ واحد جديد بحالة DRAFT.
        - لو عنده KYC (DRAFT/PENDING/REJECTED) → نحدث البيانات ونرجع الحالة DRAFT.
        - لو APPROVED → نرفض تعديل من هنا.
        ملاحظة: الصور لا يتم التعامل معها هنا إطلاقًا.
        """
        kyc = cls.get_by_user_id(db, user_id)

        if kyc and kyc.status == schemas.KYCStatus.APPROVED.value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="تمت الموافقة على KYC مسبقًا، لا يمكن تعديله.",
            )

        if not kyc:
            kyc = models.UserKYC(
                user_id=user_id,
                id_type=payload.id_type.value,
                id_number=payload.id_number,
                #  الصور تكون None في مرحلة DRAFT (لا نملأها هنا)
                id_front_image=None,
                id_back_image=None,
                selfie_image=None,
                status=schemas.KYCStatus.DRAFT.value,
                created_at=datetime.utcnow(),
                id_expiry=payload.id_expiry,
                nationality=payload.nationality,
                rejection_reason=None,
                verified_by=None,
                verified_at=None,
            )
            db.add(kyc)
        else:
            # تحديث البيانات وإعادة الحالة DRAFT
            kyc.id_type = payload.id_type.value
            kyc.id_number = payload.id_number
            kyc.id_expiry = payload.id_expiry
            kyc.nationality = payload.nationality

            kyc.status = schemas.KYCStatus.DRAFT.value
            kyc.rejection_reason = None
            kyc.verified_by = None
            kyc.verified_at = None
            db.add(kyc)

        address = db.scalar(
            select(Address).where(Address.user_id == user_id)
        )

        if not address:
            address = Address(
                user_id=user_id,
                country=payload.country,
                city=payload.city,
                location=payload.location,
                apartment=payload.apartment,
            )
            db.add(address)
        else:
            address.country = payload.country
            address.city = payload.city
            address.location = payload.location
            address.apartment = payload.apartment
            db.add(address)

        db.commit()
        return cls.get_by_user_id(db, user_id)

    @classmethod
    def update_kyc_for_user(
        cls,
        db: Session,
        user_id: int,
        payload: schemas.UserKYCUpdate,  #  بيانات فقط
    ) -> models.UserKYC:
        """
        تعديل جزئي من جهة العميل طالما KYC ليس APPROVED.
        ملاحظة: لا نعدل الصور من هنا.
        """
        kyc = cls.get_by_user_id(db, user_id)
        if not kyc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="لم يتم تقديم KYC لهذا المستخدم بعد",
            )

        if kyc.status == schemas.KYCStatus.APPROVED.value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="تمت الموافقة على KYC مسبقًا، لا يمكن تعديله.",
            )

        if payload.id_type is not None:
            kyc.id_type = payload.id_type.value
        if payload.id_number is not None:
            kyc.id_number = payload.id_number
        if payload.id_expiry is not None:
            kyc.id_expiry = payload.id_expiry
        if payload.nationality is not None:
            kyc.nationality = payload.nationality

        address = db.scalar(
            select(Address).where(Address.user_id == user_id)
        )

        if not address:
            address = Address(user_id=user_id)
            db.add(address)

        if payload.country is not None:
            address.country = payload.country
        if payload.city is not None:
            address.city = payload.city
        if payload.location is not None:
            address.location = payload.location
        if payload.apartment is not None:
            address.apartment = payload.apartment

        # لما يعدل العميل نرجع الحالة DRAFT حتى يرفع الصور/يعيد رفعها
        kyc.status = schemas.KYCStatus.DRAFT.value
        kyc.rejection_reason = None
        kyc.verified_by = None
        kyc.verified_at = None

        db.add(kyc)
        db.commit()
        return cls.get_by_user_id(db, user_id)

    # ===== من جهة الموظف =====

    @classmethod
    def review_kyc(
        cls,
        db: Session,
        kyc: models.UserKYC,
        decision: schemas.KYCReviewDecision,
        staff_id: int,
    ) -> models.UserKYC:
        """
        مراجعة KYC:
        - APPROVED → يجب أن لا يكون هناك rejection_reason
        - REJECTED → يجب أن يكون هناك rejection_reason
        """
        if decision.status == schemas.KYCStatus.REJECTED and not decision.rejection_reason:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="سبب الرفض مطلوب عند رفض KYC.",
            )

        if decision.status == schemas.KYCStatus.APPROVED:
            kyc.status = schemas.KYCStatus.APPROVED.value
            kyc.rejection_reason = None
        elif decision.status == schemas.KYCStatus.REJECTED:
            kyc.status = schemas.KYCStatus.REJECTED.value
            kyc.rejection_reason = decision.rejection_reason

        kyc.verified_by = staff_id
        kyc.verified_at = datetime.utcnow()

        #  هنا نحدث users.is_verified بناءً على قرار الموظف
        from apps.auth import models as auth_models

        user = db.get(auth_models.User, kyc.user_id)
        if user:
            user.is_verified = (decision.status == schemas.KYCStatus.APPROVED)
            db.add(user)

        db.add(kyc)
        db.commit()
        db.refresh(kyc)
        return kyc


# ====== تخزين الملفات محليًا (Windows) ======

KYC_UPLOAD_DIR = Path(os.getenv("KYC_UPLOAD_DIR", r"C:\wallet_system_data\uploads"))
KYC_MAX_MB = int(os.getenv("KYC_MAX_MB", "5"))
MAX_BYTES = KYC_MAX_MB * 1024 * 1024

ALLOWED_MIME = {"image/jpeg": ".jpg", "image/png": ".png"}


class KYCFileStorage:
    @staticmethod
    async def save_image(*, user_id: int, id_type: str, kind: str, file: UploadFile) -> str:
        if file.content_type not in ALLOWED_MIME:
            raise HTTPException(status_code=400, detail="نوع الملف غير مسموح (JPEG/PNG فقط)")

        content = await file.read()
        if not content:
            raise HTTPException(status_code=400, detail="الملف فارغ")
        if len(content) > MAX_BYTES:
            raise HTTPException(status_code=400, detail=f"حجم الملف كبير (الحد {KYC_MAX_MB}MB)")

        ext = ALLOWED_MIME[file.content_type]
        filename = f"{kind}_{uuid.uuid4().hex}{ext}"
        rel_path = str(Path("kyc") / str(user_id) / id_type / filename)

        abs_path = (KYC_UPLOAD_DIR / rel_path).resolve()
        base = KYC_UPLOAD_DIR.resolve()

        try:
            abs_path.relative_to(base)
        except ValueError:
            raise HTTPException(status_code=400, detail="مسار غير صالح")

        abs_path.parent.mkdir(parents=True, exist_ok=True)
        abs_path.write_bytes(content)

        return rel_path