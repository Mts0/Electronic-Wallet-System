from fastapi import APIRouter, Depends, HTTPException, status, Request, Body
from sqlalchemy.orm import Session
from sqlalchemy import select

from apps.core.database import get_session
from apps.utils.validators import get_client_ip, get_device_info

from . import schemas, services, models
from .dependencies import get_current_active_user
from .services import UserService, OTPService, AuthService


from fastapi.security import OAuth2PasswordRequestForm


router = APIRouter(prefix="/auth", tags=["Authentication"])


# ========== REGISTER ==========

@router.post("/register", response_model=schemas.UserResponse)
def register_user(
    user_data: schemas.UserCreate,
    request: Request,
    db: Session = Depends(get_session),
):
    # إنشاء المستخدم
    user = UserService.create_user(db, user_data)

    # إنشاء رمز تحقق للتسجيل
    device_info = get_device_info(request)
    OTPService.create_verification(
        db=db,
        user=user,
        verification_type=schemas.VerificationType.REGISTER,
        device_info=device_info,
    )

    return user


@router.post("/request-otp", response_model=schemas.MessageResponse)
def request_otp(
    payload: schemas.OTPRequest,
    request: Request,
    db: Session = Depends(get_session),
):
    user = UserService.get_user_by_phone(db, payload.phone_number)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستخدم غير موجود",
        )

    elif payload.verification_type == schemas.VerificationType.REGISTER and user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="هذا الحساب موثّق بالفعل",
        )

    device_info = get_device_info(request)
    OTPService.create_verification(
        db=db,
        user=user,
        verification_type=payload.verification_type,
        device_info=device_info,
    )

    return schemas.MessageResponse(message="تم إرسال رمز التحقق")


@router.post("/verify-otp", response_model=schemas.MessageResponse)
def verify_otp(
    payload: schemas.OTPVerify,
    db: Session = Depends(get_session),
):
    user = UserService.get_user_by_phone(db, payload.phone_number)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستخدم غير موجود",
        )

    OTPService.verify_otp(
        db=db,
        user=user,
        otp_code=payload.otp_code,
        verification_type=payload.verification_type,
    )

    # لو نوع التحقق تسجيل، فعل المستخدم
    if payload.verification_type == schemas.VerificationType.REGISTER:
        user.is_active = True
        #user.is_verified = True
        db.add(user)
        db.commit()




    return schemas.MessageResponse(message="تم التحقق من الرمز بنجاح")


# ========== LOGIN ==========

@router.post("/login", response_model=schemas.TokenResponse)
def login(
    login_data: schemas.UserLogin,
    request: Request,
    db: Session = Depends(get_session),
):
    ip = get_client_ip(request)

    device_info = get_device_info(request)

    # التحقق من صحة بيانات الدخول
    user = AuthService.authenticate_user(db, login_data)
    if not user:
        # log failed
        if login_data.phone_number:
            u = UserService.get_user_by_phone(db, login_data.phone_number)
        elif login_data.email:
            u = UserService.get_user_by_email(db, login_data.email)
        else:
            u = None

        if u:
            UserService.log_login_attempt(
                db=db,
                user_id=u.user_id,
                ip_address=ip,
                device_info=device_info,
                status="FAILED",
            )

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="بيانات الدخول غير صحيحة",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="الحساب غير نشط",
        )

    # log success
    UserService.log_login_attempt(
        db=db,
        user_id=user.user_id,
        ip_address=ip,
        device_info=device_info,
        status="SUCCESS",
    )

    # إنشاء التوكنات
    tokens = AuthService.create_tokens_for_user(user)

    # حفظ الجلسة في user_sessions باستخدام access_token
    if tokens.get("access_token"):
        UserService.create_session(
            db=db,
            user=user,
            token=tokens["access_token"],
            ip_address=ip,
            device_info=device_info,
        )

    return schemas.TokenResponse(
        access_token=tokens["access_token"],
        refresh_token=tokens.get("refresh_token"),
        user=user,
    )





@router.post("/token", response_model=schemas.TokenResponse)
def login_form(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_session),
):
    ip = get_client_ip(request)
    device_info = get_device_info(request)

    username = (form_data.username or "").strip()
    login_data = schemas.UserLogin(
        phone_number=None if "@" in username else username,
        email=username if "@" in username else None,
        password=form_data.password,
    )

    # ثم نفس كودك الحالي (authenticate/log/tokens/session/return)
    user = AuthService.authenticate_user(db, login_data)
    if not user:
        # log failed
        if login_data.phone_number:
            u = UserService.get_user_by_phone(db, login_data.phone_number)
        elif login_data.email:
            u = UserService.get_user_by_email(db, login_data.email)
        else:
            u = None

        if u:
            UserService.log_login_attempt(
                db=db,
                user_id=u.user_id,
                ip_address=ip,
                device_info=device_info,
                status="FAILED",
            )

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="بيانات الدخول غير صحيحة",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="الحساب غير نشط",
        )

    UserService.log_login_attempt(
        db=db,
        user_id=user.user_id,
        ip_address=ip,
        device_info=device_info,
        status="SUCCESS",
    )

    tokens = AuthService.create_tokens_for_user(user)
    if tokens.get("access_token"):

            UserService.create_session(
                db=db,
                user=user,
                token=tokens["access_token"],
                ip_address=ip,
                device_info=device_info,
            )

    return schemas.TokenResponse(
        access_token=tokens["access_token"],
        refresh_token=tokens.get("refresh_token"),
        user=user,
    )




# ========== PROFILE / ME ==========

@router.get("/me", response_model=schemas.UserResponse)
def get_me(
    current_user: models.User = Depends(get_current_active_user),
):
    return current_user


# ========== CHANGE PASSWORD (logged-in) ==========

@router.post("/change-password", response_model=schemas.MessageResponse)
def change_password(
    payload: schemas.PasswordChange,
    request: Request,
    db: Session = Depends(get_session),
    current_user: models.User = Depends(get_current_active_user),
):
    AuthService.change_password(db, current_user, payload)

    # سجل في جدول password_reset كـ manual_change
    UserService.save_password_reset(
        db=db,
        user=current_user,
        method="USER_CHANGE",
        ip_address=get_client_ip(request),
    )

    return schemas.MessageResponse(message="تم تغيير كلمة المرور بنجاح")


# ========== FORGOT PASSWORD FLOW ==========

@router.post("/password/forgot", response_model=schemas.MessageResponse)
def forgot_password_request(
    payload: schemas.PasswordResetRequest,
    request: Request,
    db: Session = Depends(get_session),
):
    user: models.User | None = None

    if payload.phone_number:
        user = UserService.get_user_by_phone(db, payload.phone_number)
    elif payload.email:
        user = UserService.get_user_by_email(db, payload.email)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستخدم غير موجود",
        )

    device_info = get_device_info(request)
    OTPService.create_verification(
        db=db,
        user=user,
        verification_type=schemas.VerificationType.PASSWORD_RESET,
        device_info=device_info,
    )

    return schemas.MessageResponse(message="تم إرسال رمز استعادة كلمة المرور")


@router.post("/password/reset", response_model=schemas.MessageResponse)
def forgot_password_confirm(
    payload: schemas.PasswordResetConfirm,
    request: Request,
    db: Session = Depends(get_session),
):
    user: models.User | None = None

    if payload.phone_number:
        user = UserService.get_user_by_phone(db, payload.phone_number)
    elif payload.email:
        user = UserService.get_user_by_email(db, payload.email)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستخدم غير موجود",
        )

    # تحقق من رمز التحقق
    OTPService.verify_otp(
        db=db,
        user=user,
        otp_code=payload.otp_code,
        verification_type=schemas.VerificationType.PASSWORD_RESET,
    )

    # حدّث كلمة المرور
    validate_password = services.validate_password if hasattr(services, "validate_password") else None
    if validate_password:
        validate_password(payload.new_password)

    user.password_hash = services.security.get_password_hash(payload.new_password)
    user.updated_at = None  # أو datetime.utcnow() لو أضفت حقل updated_at
    db.add(user)
    db.commit()

    # سجل في password_reset
    from apps.utils.validators import get_client_ip  # لتجنب الدورة في الأعلى
    UserService.save_password_reset(
        db=db,
        user=user,
        method="FORGOT_PASSWORD",
        ip_address=get_client_ip(request),
    )

    return schemas.MessageResponse(message="تم تعيين كلمة المرور الجديدة بنجاح")


# ========== LOGOUT ==========

@router.post("/logout", response_model=schemas.MessageResponse)
def logout(
    request: Request,
    db: Session = Depends(get_session),
    current_user: models.User = Depends(get_current_active_user),
):
    # استخرج التوكن الحالي من الـ Header
    token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="لا يوجد رمز دخول في الطلب",
        )

    # تعطيل الجلسة الحالية
    UserService.deactivate_session_by_token(
        db=db,
        user_id=current_user.user_id,
        token=token,
    )

    return schemas.MessageResponse(message="تم تسجيل الخروج بنجاح")
