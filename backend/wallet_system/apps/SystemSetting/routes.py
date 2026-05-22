# SystemSetting/routes.py

from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff import models as staff_models
from . import schemas, models
from .services import SystemSettingService
from .dependencies import (
    require_staff_with_permission,
    get_setting_or_404,
)

router = APIRouter(
    prefix="/system-settings",
    tags=["System Settings"],
)


# ========== جزء عام (Public) ==========

@router.get(
    "/public",
    response_model=List[schemas.SystemSettingPublicOut],
)
def list_public_settings(
    db: Session = Depends(get_session),
):
    settings = SystemSettingService.list_public_settings(db)
    return settings


@router.get(
    "/public/{setting_name}",
    response_model=schemas.SystemSettingPublicOut,
)
def get_public_setting_by_name(
    setting_name: str,
    db: Session = Depends(get_session),
):
    setting = SystemSettingService.get_setting_by_name(db, setting_name)
    from fastapi import HTTPException
    if not setting or not setting.is_public:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الإعداد غير موجود أو غير متاح للعامة",
        )
    return setting


# ========== جزء الموظفين (STAFF) ==========

@router.get(
    "",
    response_model=List[schemas.SystemSettingOut],
)
def list_system_settings(
    is_public: Optional[bool] = Query(None),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_system_settings")
    ),
):
    settings = SystemSettingService.list_settings(db, is_public=is_public)
    return settings


@router.get(
    "/{setting_id}",
    response_model=schemas.SystemSettingOut,
)
def get_system_setting(
    setting: models.SystemSetting = Depends(get_setting_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_system_settings")
    ),
):
    return setting


@router.post(
    "",
    response_model=schemas.SystemSettingOut,
    status_code=status.HTTP_201_CREATED,
)
def create_system_setting(
    payload: schemas.SystemSettingCreate,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_system_settings")
    ),
):
    setting = SystemSettingService.create_setting(
        db=db,
        payload=payload,
        staff_id=staff.staff_id,
    )
    return setting


@router.patch(
    "/{setting_id}",
    response_model=schemas.SystemSettingOut,
)
def update_system_setting(
    payload: schemas.SystemSettingUpdate,
    db: Session = Depends(get_session),
    setting: models.SystemSetting = Depends(get_setting_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_system_settings")
    ),
):
    setting = SystemSettingService.update_setting(
        db=db,
        setting=setting,
        payload=payload,
        staff_id=staff.staff_id,
    )
    return setting


@router.get(
    "/{setting_id}/updates",
    response_model=List[schemas.SettingsUpdateOut],
)
def list_system_setting_updates(
    setting_id: int,
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_system_settings_history")
    ),
):
    updates = SystemSettingService.list_setting_updates(
        db=db,
        setting_id=setting_id,
        limit=limit,
    )
    return updates
