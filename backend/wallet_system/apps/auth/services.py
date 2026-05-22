from datetime import datetime, timedelta
import random
from apps.wallets.services import WalletService
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, select
from apps.core import security
from apps.utils.validators import validate_phone_number, validate_password
from . import models, schemas



class UserService:
    @staticmethod
    def create_user(db: Session, user_data: schemas.UserCreate) -> models.User:
        # تحقق من رقم الهاتف وكلمة المرور
        validate_phone_number(user_data.phone_number)
        validate_password(user_data.password)

        # التحقق من عدم وجود مستخدم بنفس الهاتف أو البريد
        existing_user = db.scalar(
            select(models.User).where(
                or_(
                    models.User.phone_number == user_data.phone_number,
                    models.User.email == user_data.email if user_data.email else False,
                )
            )
        )
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="رقم الهاتف أو البريد الإلكتروني مستخدم مسبقًا",
            )

        hashed_password = security.get_password_hash(user_data.password)

        user = models.User(
            full_name=user_data.full_name,
            phone_number=user_data.phone_number,
            email=user_data.email,
            password_hash=hashed_password,
            gender=user_data.gender.value if user_data.gender else None,
            date_of_birth=user_data.date_of_birth,
            user_type="CUSTOMER",
            is_verified=False,
            is_active=False,
        )

        db.add(user)

        db.flush()  # مهم جدًا: يعطي user.user_id قبل الـ commit
        from apps.wallets.models import Wallet
        #  إنشاء المحفظة مباشرة بعد إنشاء المستخدم
        wallet = WalletService.get_or_create_wallet_for_user(db, user.user_id)
        WalletService.ensure_default_accounts(db, wallet, currency_ids=[1, 2, 3])

        db.commit()
        db.refresh(user)
        return user

    # ---- Getters ----

    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> models.User | None:
        return db.get(models.User, user_id)

    @staticmethod
    def get_user_by_phone(db: Session, phone_number: str) -> models.User | None:
        return db.scalar(
            select(models.User).where(models.User.phone_number == phone_number)
        )

    @staticmethod
    def get_user_by_email(db: Session, email: str) -> models.User | None:
        return db.scalar(select(models.User).where(models.User.email == email))

    # ---- Sessions / Logs ----

    @staticmethod
    def create_session(
            db: Session,
            user: models.User,
            token: str,
            ip_address: str | None,
            device_info: str | None,
    ) -> models.UserSession:
        session = models.UserSession(
            user_id=user.user_id,
            token=token,
            ip_address=ip_address,
            device_info=device_info,
            is_active=True,
            created_at=datetime.utcnow(),
            last_access=datetime.utcnow(),
        )
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    @staticmethod
    def deactivate_session_by_token(
            db: Session, user_id: int, token: str
    ) -> None:
        session = db.scalar(
            select(models.UserSession).where(
                models.UserSession.user_id == user_id,
                models.UserSession.token == token,
                models.UserSession.is_active == True,  # noqa: E712
            )
        )
        if session:
            session.is_active = False
            db.add(session)
            db.commit()

    @staticmethod
    def log_login_attempt(
            db: Session, user_id: int, ip_address: str | None, device_info: str | None, status: str
    ) -> models.LoginTry:
        login_try = models.LoginTry(
            user_id=user_id,
            ip_address=ip_address,
            device_info=device_info,
            status=status,
        )
        db.add(login_try)
        db.commit()
        db.refresh(login_try)
        return login_try

    @staticmethod
    def save_password_reset(
            db: Session, user: models.User, method: str, ip_address: str | None
    ) -> models.PasswordReset:
        pr = models.PasswordReset(
            user_id=user.user_id,
            method=method,
            ip_address=ip_address,
            changed_at=datetime.utcnow(),
        )
        db.add(pr)
        db.commit()
        db.refresh(pr)
        return pr






class OTPService:
    OTP_LENGTH = 6
    OTP_EXP_MINUTES = 5
    MAX_TRIES = 5

    @staticmethod
    def _generate_otp() -> str:
        # رقم من 6 خانات
        return f"{random.randint(0, 999999):06d}"

    @classmethod
    def create_verification(
            cls,
            db: Session,
            user: models.User,
            verification_type: schemas.VerificationType,
            device_info: str | None,
    ) -> models.Verification:
        # ممكن تلغي الأكواد القديمة من نفس النوع
        # أو تتركها – هنا نتركها لأغراض السجل
        # اجعل آخر كود فقط هو الصالح لكل (user_id, verification_type)
        db.query(models.Verification).filter(
            models.Verification.user_id == user.user_id,
            models.Verification.verification_type == verification_type.value,
            models.Verification.is_used == False,
        ).update({"is_used": True}, synchronize_session=False)

        otp_code = cls._generate_otp()
        otp_expiry = datetime.utcnow() + timedelta(minutes=cls.OTP_EXP_MINUTES)

        verification = models.Verification(
            user_id=user.user_id,
            otp_code=otp_code,
            otp_expiry=otp_expiry,
            is_used=False,
            device_info=device_info,
            verification_type=verification_type.value,
            try_count=0,
        )
        db.add(verification)
        db.commit()
        db.refresh(verification)
        return verification

    @classmethod
    def verify_otp(
            cls,
            db: Session,
            user: models.User,
            otp_code: str,
            verification_type: schemas.VerificationType,
    ) -> models.Verification:
        verification = (
            db.query(models.Verification)
            .filter(
                models.Verification.user_id == user.user_id,
                models.Verification.verification_type == verification_type.value,
                models.Verification.is_used == False,  # noqa: E712
            )
            .order_by(models.Verification.created_at.desc())
            .first()
        )

        if not verification:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="لا يوجد رمز تحقق صالح",
            )

        # تحقق من المحاولات
        if verification.try_count >= cls.MAX_TRIES:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="تم تجاوز الحد المسموح لمحاولات التحقق",
            )

        # زيادة العداد
        verification.try_count += 1
        db.add(verification)
        db.commit()
        db.refresh(verification)

        # تحقق من انتهاء الصلاحية
        if verification.otp_expiry and verification.otp_expiry < datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="رمز التحقق منتهي الصلاحية",
            )

        if verification.otp_code != otp_code:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="رمز التحقق غير صحيح",
            )

        verification.is_used = True

        db.add(verification)
        db.commit()
        db.refresh(verification)
        return verification





class AuthService:
    @staticmethod
    def authenticate_user(
            db: Session, login_data: schemas.UserLogin
    ) -> models.User | None:
        user: models.User | None = None

        if login_data.phone_number:
            user = UserService.get_user_by_phone(db, login_data.phone_number)
        elif login_data.email:
            user = UserService.get_user_by_email(db, login_data.email)

        if not user:
            return None

        if not security.verify_password(login_data.password, user.password_hash):
            return None

        return user

    @staticmethod
    def create_tokens_for_user(user: models.User) -> dict:
        # نفترض وجود دوال في apps.core.security
        access_token = security.create_access_token({"sub": str(user.user_id)})
        # لو ما عندك refresh_token تقدر ترجع None
        refresh_token = security.create_refresh_token({"sub": str(user.user_id)}) \
            if hasattr(security, "create_refresh_token") else None

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
        }

    @staticmethod
    def change_password(
            db: Session,
            user: models.User,
            payload: schemas.PasswordChange,
    ) -> None:
        if not security.verify_password(payload.current_password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="كلمة المرور الحالية غير صحيحة",
            )

        validate_password(payload.new_password)
        user.password_hash = security.get_password_hash(payload.new_password)
        user.updated_at = datetime.utcnow()
        db.add(user)
        db.commit()



