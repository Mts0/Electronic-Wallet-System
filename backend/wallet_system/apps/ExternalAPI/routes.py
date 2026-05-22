# ExternalAPI/routes.py

from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..staff import models as staff_models
from . import schemas, models
from .services import ExternalServiceService
from .dependencies import (
    require_staff_with_permission,
    get_external_service_or_404,
)

router = APIRouter(
    prefix="/external-services",
    tags=["External Services / Integrations"],
)


# ========= إدارة الخدمات الخارجية (STAFF) =========

@router.get(
    "",
    response_model=List[schemas.ExternalServiceResponse],
)
def list_external_services(
    is_active: Optional[bool] = None,
    service_type: Optional[schemas.ServiceType] = Query(None),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_external_services")
    ),
):
    services = ExternalServiceService.list_services(
        db=db,
        is_active=is_active,
        service_type=service_type,
    )
    return services


@router.post(
    "",
    response_model=schemas.ExternalServiceResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_external_service(
    payload: schemas.ExternalServiceCreate,
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_external_services")
    ),
):
    service = ExternalServiceService.create_service(db, payload)
    return service


@router.get(
    "/{service_id}",
    response_model=schemas.ExternalServiceResponse,
)
def get_external_service(
    service: models.ExternalService = Depends(get_external_service_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_external_services")
    ),
):
    return service


@router.patch(
    "/{service_id}",
    response_model=schemas.ExternalServiceResponse,
)
def update_external_service(
    payload: schemas.ExternalServiceUpdate,
    db: Session = Depends(get_session),
    service: models.ExternalService = Depends(get_external_service_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_external_services")
    ),
):
    service = ExternalServiceService.update_service(db, service, payload)
    return service


@router.post(
    "/{service_id}/activate",
    response_model=schemas.ExternalServiceResponse,
)
def activate_external_service(
    db: Session = Depends(get_session),
    service: models.ExternalService = Depends(get_external_service_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_external_services")
    ),
):
    service = ExternalServiceService.set_service_active(db, service, True)
    return service


@router.post(
    "/{service_id}/deactivate",
    response_model=schemas.ExternalServiceResponse,
)
def deactivate_external_service(
    db: Session = Depends(get_session),
    service: models.ExternalService = Depends(get_external_service_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("manage_external_services")
    ),
):
    service = ExternalServiceService.set_service_active(db, service, False)
    return service


# ========= Logs =========

@router.get(
    "/{service_id}/logs",
    response_model=List[schemas.ExternalServiceLogResponse],
)
def list_external_service_logs(
    service_id: int,
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("view_external_service_logs")
    ),
):
    logs = ExternalServiceService.list_logs(db, service_id, limit=limit)
    return logs


# ========= Test Call =========

@router.post(
    "/{service_id}/test",
    response_model=schemas.ServiceTestResponse,
)
def test_external_service(
    payload: schemas.ServiceTestRequest,
    db: Session = Depends(get_session),
    service: models.ExternalService = Depends(get_external_service_or_404),
    staff: staff_models.Staff = Depends(
        require_staff_with_permission("test_external_services")
    ),
):
    log = ExternalServiceService.test_service_call(db, service, payload)
    return schemas.ServiceTestResponse(log=log)
