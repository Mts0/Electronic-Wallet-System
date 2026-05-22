from typing import Optional, List

from fastapi import Depends, HTTPException, status, Header, Request
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff.dependencies import require_permission
from . import models
from .services import APIConsumerService


async def get_api_consumer_from_key(
    request: Request,
    db: Session = Depends(get_session),
    x_api_key: Optional[str] = Header(default=None, alias="X-API-Key"),
) -> models.APIConsumer:
    """
    Dependency لاستخدامه في الـ endpoints التي تستدعى من مستهلكي الـ API الخارجيين.

    يتحقق من:
    - وجود X-API-Key
    - صحة الـ key ووجود consumer
    - حالة is_active
    - allowed_ips (لو محددة)
    - allowed_endpoints (لو محددة)
    """
    if not x_api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="مفتاح الـ API مفقود",
        )

    consumer = APIConsumerService.get_consumer_by_key(db, x_api_key)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="مفتاح الـ API غير صالح",
        )

    if not consumer.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="هذا المستهلك موقوف",
        )

    # التحقق من الـ IP إن وُجدت قيود
    client_ip = request.client.host if request.client else None
    if consumer.allowed_ips and client_ip:
        allowed_ips = [
            ip.strip()
            for ip in consumer.allowed_ips.split(",")
            if ip.strip()
        ]
        if allowed_ips and client_ip not in allowed_ips:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="عنوان الـ IP غير مسموح به",
            )

    # التحقق من الـ Endpoints لو فيه JSON محدد
    if consumer.allowed_endpoints:
        try:
            # نفترض allowed_endpoints عبارة عن:
            # dict: {"paths": ["/v1/pay", "/v1/balance"]}
            # أو مباشرة list: ["/v1/pay", "/v1/balance"]
            paths: List[str] = []
            if isinstance(consumer.allowed_endpoints, dict):
                paths = consumer.allowed_endpoints.get("paths", [])
            elif isinstance(consumer.allowed_endpoints, list):
                paths = consumer.allowed_endpoints
            current_path = request.url.path

            if paths:
                # نسمح بالمطابقة الكاملة أو بداية المسار (prefix)
                if not any(
                    current_path == p or current_path.startswith(str(p))
                    for p in paths
                ):
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="هذا المسار غير مسموح لهذا الـ API key",
                    )
        except Exception:
            # لو صيغة JSON فيها مشكلة ما نكسر النظام (تقدر تشددها لاحقًا)
            pass

    return consumer


# Dependency مختصر لموظفي النظام مع صلاحيات معينة
def require_staff_with_permission(permission_name: str):
    """
    مثال الاستخدام في الراوتر:
    staff: Staff = Depends(require_staff_with_permission("view_api_consumers"))
    """
    return require_permission(permission_name)
