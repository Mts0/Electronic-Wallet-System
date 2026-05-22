from typing import List

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff import models as staff_models
from . import schemas
from .services import APIConsumerService
from .dependencies import get_api_consumer_from_key, require_staff_with_permission

router = APIRouter(prefix="/api-consumers", tags=["API Consumers"])


# ====== إدارة الـ Consumers (لوحة الموظفين) ======

@router.get(
    "",
    response_model=List[schemas.APIConsumerOut],
)
def list_api_consumers(
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_api_consumers")
    ),
):
    consumers = APIConsumerService.list_consumers(db)
    return consumers


@router.post(
    "",
    response_model=schemas.APIConsumerOut,
    status_code=status.HTTP_201_CREATED,
)
def create_api_consumer(
    payload: schemas.APIConsumerCreate,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_api_consumers")
    ),
):
    consumer = APIConsumerService.create_consumer(db, payload)
    return consumer


@router.get(
    "/{consumer_id}",
    response_model=schemas.APIConsumerOut,
)
def get_api_consumer(
    consumer_id: int,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_api_consumers")
    ),
):
    consumer = APIConsumerService.get_consumer_by_id(db, consumer_id)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستهلك غير موجود",
        )
    return consumer


@router.patch(
    "/{consumer_id}",
    response_model=schemas.APIConsumerOut,
)
def update_api_consumer(
    consumer_id: int,
    payload: schemas.APIConsumerUpdate,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_api_consumers")
    ),
):
    consumer = APIConsumerService.get_consumer_by_id(db, consumer_id)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستهلك غير موجود",
        )
    consumer = APIConsumerService.update_consumer(db, consumer, payload)
    return consumer


@router.post(
    "/{consumer_id}/activate",
    response_model=schemas.APIConsumerOut,
)
def activate_api_consumer(
    consumer_id: int,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_api_consumers")
    ),
):
    consumer = APIConsumerService.get_consumer_by_id(db, consumer_id)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستهلك غير موجود",
        )
    consumer = APIConsumerService.set_consumer_active(db, consumer, True)
    return consumer


@router.post(
    "/{consumer_id}/deactivate",
    response_model=schemas.APIConsumerOut,
)
def deactivate_api_consumer(
    consumer_id: int,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_api_consumers")
    ),
):
    consumer = APIConsumerService.get_consumer_by_id(db, consumer_id)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستهلك غير موجود",
        )
    consumer = APIConsumerService.set_consumer_active(db, consumer, False)
    return consumer


@router.post(
    "/{consumer_id}/rotate-key",
    response_model=schemas.APIKeysUpdateOut,
)
def rotate_api_key_for_consumer(
    consumer_id: int,
    payload: schemas.APIKeyRotateRequest,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("rotate_api_keys")
    ),
):
    consumer = APIConsumerService.get_consumer_by_id(db, consumer_id)
    if not consumer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="المستهلك غير موجود",
        )

    record = APIConsumerService.rotate_api_key(
        db=db,
        consumer=consumer,
        changed_by_staff_id=staff.staff_id,
    )
    # تقدر تستخدم payload.reason في audit_logs لاحقًا
    return record


@router.get(
    "/{consumer_id}/logs",
    response_model=List[schemas.APIAccessLogOut],
)
def list_api_consumer_logs(
    consumer_id: int,
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_api_logs")
    ),
):
    logs = APIConsumerService.list_consumer_logs(db, consumer_id, limit=limit)
    return logs
