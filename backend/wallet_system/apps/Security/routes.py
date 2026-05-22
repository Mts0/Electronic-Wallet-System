# apps/Security/routes.py

from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user
from ..staff import models as staff_models
from . import schemas, models
from .services import SecurityService
from .dependencies import (

    get_audit_log_or_404,


    require_staff_with_permission,
)

router = APIRouter(prefix="/security", tags=["Security & Logs"])


# ========= جزء العميل (يشوف سجلاته) =========












# ========= جزء الموظفين (STAFF) =========

# ---- SECURITY LOGS ----




# ---- REAL TIME EVENTS ----




# ---- AUDIT LOGS ----

@router.get(
    "/audit-logs",
    response_model=List[schemas.AuditLogOut],
)
def list_audit_logs(
    user_id: Optional[int] = Query(None),
    changed_by: Optional[int] = Query(None),
    action_type: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_audit_logs")
    ),
):
    logs = SecurityService.list_audit_logs(
        db=db,
        user_id=user_id,
        changed_by=changed_by,
        action_type=action_type,
        limit=limit,
    )
    return logs


@router.get(
    "/audit-logs/{audit_id}",
    response_model=schemas.AuditLogOut,
)
def get_audit_log(
    log: models.AuditLog = Depends(get_audit_log_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_audit_logs")
    ),
):
    return log


# ---- ANALYTICS LOGS ----


