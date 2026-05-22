from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from apps.core.database import get_session
from apps.core.security import decode_access_token

from . import models
from .services import UserService

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")


async def get_current_user(
        token: str = Depends(oauth2_scheme),
        db: Session = Depends(get_session),
) -> models.User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="لم يتم التحقق من الهوية",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if not token:
        raise credentials_exception

    try:
        payload = decode_access_token(token)
        user_id = int(payload.get("sub"))
    except Exception:
        raise credentials_exception

    user = UserService.get_user_by_id(db, user_id)
    if user is None:
        raise credentials_exception

    # ممكن لاحقًا تتحقق من الجلسة في جدول user_sessions بناءً على الـ token
    return user

async def get_current_active_user(
        current_user: models.User = Depends(get_current_user),
) -> models.User:
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="الحساب غير نشط",
        )

    if current_user.blocked_reason:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="الحساب محظور",
        )

    """if not current_user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="الحساب غير مُفعل (لم يتم التحقق من رقم الهاتف)",
        )"""

    return current_user


async def get_current_kyc_verified_user(
        current_user: models.User = Depends(get_current_active_user),
) -> models.User:
    if not current_user.is_verified:  # هنا is_verified = KYC ويجب تغيير الشرط الى Not
        raise HTTPException(status_code=403, detail="لا يمكن تنفيذ العمليات المالية قبل إكمال KYC")
    return current_user


async def get_current_staff_user(
        current_user: models.User = Depends(get_current_kyc_verified_user),
) -> models.User:
    if current_user.user_type != "STAFF":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="صلاحية مرفوضة. هذا المسار للموظفين فقط",
        )
    return current_user


async def get_current_customer_user(
        current_user: models.User = Depends(get_current_kyc_verified_user),
) -> models.User:
    if current_user.user_type != "CUSTOMER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="صلاحية مرفوضة. هذا المسار للعملاء فقط",
        )
    return current_user
