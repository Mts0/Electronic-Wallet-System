# apps/Security/dependencies.py

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user
from ..staff.dependencies import require_permission
from . import models
from .services import SecurityService



def get_audit_log_or_404(
    audit_id: int,
    db: Session = Depends(get_session),
) -> models.AuditLog:
    log = SecurityService.get_audit_log_by_id(db, audit_id)
    if not log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="سجل التدقيق غير موجود",
        )
    return log







def require_staff_with_permission(permission_name: str):
    """
    نفس الباترون في باقي الموديولات.
    مثال:
        staff = Depends(require_staff_with_permission("view_security_logs"))
    """
    return require_permission(permission_name)
