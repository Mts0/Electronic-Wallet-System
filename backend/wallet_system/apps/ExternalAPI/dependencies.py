# ExternalAPI/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff.dependencies import require_permission
from . import models
from .services import ExternalServiceService


def require_staff_with_permission(permission_name: str):
    """
    نفس الفكرة في باقي الموديولات:
    staff = Depends(require_staff_with_permission("manage_external_services"))
    """
    return require_permission(permission_name)


def get_external_service_or_404(
    service_id: int,
    db: Session = Depends(get_session),
) -> models.ExternalService:
    service = ExternalServiceService.get_service_by_id(db, service_id)
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الخدمة الخارجية غير موجودة",
        )
    return service
