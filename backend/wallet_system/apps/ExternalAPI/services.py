# ExternalAPI/services.py

import time
from datetime import datetime
from typing import List, Optional, Dict, Any

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from . import models, schemas


class ExternalServiceService:
    """
    Service layer لإدارة:
    - external_services
    - external_service_logs
    - اختبار الاتصال بالخدمات الخارجية
    """

    # ========= Getters =========

    @staticmethod
    def list_services(
        db: Session,
        is_active: Optional[bool] = None,
        service_type: Optional[schemas.ServiceType] = None,
    ) -> List[models.ExternalService]:
        stmt = select(models.ExternalService)

        if is_active is not None:
            stmt = stmt.where(models.ExternalService.is_active == is_active)

        if service_type is not None:
            stmt = stmt.where(models.ExternalService.type == service_type.value)

        stmt = stmt.order_by(models.ExternalService.created_at.desc())
        return list(db.scalars(stmt))

    @staticmethod
    def get_service_by_id(
        db: Session, service_id: int
    ) -> Optional[models.ExternalService]:
        return db.get(models.ExternalService, service_id)

    @staticmethod
    def get_service_by_name(
        db: Session, name: str
    ) -> Optional[models.ExternalService]:
        return db.scalar(
            select(models.ExternalService).where(models.ExternalService.name == name)
        )

    # ========= CRUD =========

    @staticmethod
    def create_service(
        db: Session, payload: schemas.ExternalServiceCreate
    ) -> models.ExternalService:
        # [اختياري] التأكد من عدم تكرار الاسم
        existing = ExternalServiceService.get_service_by_name(db, payload.name)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="اسم الخدمة مستخدم مسبقًا",
            )

        service = models.ExternalService(
            name=payload.name,
            base_url=payload.base_url,
            auth_type=payload.auth_type.value,
            api_key=payload.api_key,
            secret_key=payload.secret_key,
            webhook_url=payload.webhook_url,
            is_active=payload.is_active,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(service)
        db.commit()
        db.refresh(service)
        return service

    @staticmethod
    def update_service(
        db: Session,
        service: models.ExternalService,
        payload: schemas.ExternalServiceUpdate,
    ) -> models.ExternalService:
        if payload.name is not None:
            service.name = payload.name
        if payload.base_url is not None:
            service.base_url = payload.base_url
        if payload.auth_type is not None:
            service.auth_type = payload.auth_type.value
        if payload.api_key is not None:
            service.api_key = payload.api_key
        if payload.secret_key is not None:
            service.secret_key = payload.secret_key
        if payload.webhook_url is not None:
            service.webhook_url = payload.webhook_url
        if payload.is_active is not None:
            service.is_active = payload.is_active

        service.updated_at = datetime.utcnow()
        db.add(service)
        db.commit()
        db.refresh(service)
        return service

    @staticmethod
    def set_service_active(
        db: Session, service: models.ExternalService, is_active: bool
    ) -> models.ExternalService:
        service.is_active = is_active
        service.updated_at = datetime.utcnow()
        db.add(service)
        db.commit()
        db.refresh(service)
        return service

    # ========= Logs =========

    @staticmethod
    def log_call(
        db: Session,
        service: models.ExternalService,
        endpoint: Optional[str],
        http_method: Optional[str],
        request_headers: Optional[Dict[str, Any]],
        request_body: Optional[Dict[str, Any]],
        response_status: Optional[int],
        response_headers: Optional[Dict[str, Any]],
        response_body: Optional[Any],
        execution_time_ms: Optional[int],
        error_message: Optional[str] = None,
    ) -> models.ExternalServiceLog:
        log = models.ExternalServiceLog(
            service_id=service.service_id,
            endpoint=endpoint,
            http_method=http_method,
            request_headers=request_headers,
            request_body=request_body,
            response_status=response_status,
            response_headers=response_headers,
            response_body=response_body,
            execution_time=execution_time_ms,
            error_message=error_message,
            created_at=datetime.utcnow(),
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        return log

    @staticmethod
    def list_logs(
        db: Session, service_id: int, limit: int = 100
    ) -> List[models.ExternalServiceLog]:
        return list(
            db.scalars(
                select(models.ExternalServiceLog)
                .where(models.ExternalServiceLog.service_id == service_id)
                .order_by(models.ExternalServiceLog.created_at.desc())
                .limit(limit)
            )
        )

    # ========= Test call =========

    @classmethod
    def test_service_call(
        cls,
        db: Session,
        service: models.ExternalService,
        payload: schemas.ServiceTestRequest,
    ) -> models.ExternalServiceLog:
        """
        ينفّذ طلب HTTP فعلي (باستخدام httpx) على الخدمة الخارجية،
        ويسجل الـ log في external_service_logs، ثم يرجع الـ log.
        """
        try:
            import httpx
        except ImportError:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="المكتبة httpx غير مثبتة. الرجاء تثبيتها أولاً.",
            )

        if not service.base_url:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="لا يوجد base_url معرف لهذه الخدمة",
            )

        method = (payload.method or "GET").upper()
        endpoint = payload.endpoint or ""
        base = service.base_url.rstrip("/")
        path = endpoint.lstrip("/")
        url = f"{base}/{path}" if path else base

        # إعداد الهيدر
        headers: Dict[str, Any] = {}
        if payload.headers:
            headers.update(payload.headers)

        auth = None

        # إعداد الـ Auth حسب نوع الخدمة
        auth_type = (service.auth_type or "").lower()
        if auth_type == schemas.AuthType.BEARER_TOKEN.value:
            if service.api_key:
                headers.setdefault("Authorization", f"Bearer {service.api_key}")
        elif auth_type == schemas.AuthType.BASIC_AUTH.value:
            if service.api_key and service.secret_key:
                auth = (service.api_key, service.secret_key)
        elif auth_type == schemas.AuthType.API_KEY.value:
            if service.api_key:
                headers.setdefault("X-API-Key", service.api_key)

        request_body = payload.payload or None

        start_ns = time.monotonic_ns()
        response_status: Optional[int] = None
        response_headers: Optional[Dict[str, Any]] = None
        response_body: Optional[Any] = None
        error_message: Optional[str] = None

        try:
            with httpx.Client(timeout=10.0) as client:
                resp = client.request(
                    method=method,
                    url=url,
                    json=request_body,
                    headers=headers,
                    auth=auth,
                )
            response_status = resp.status_code
            response_headers = dict(resp.headers)

            # محاولة قراءة JSON، ولو فشلت خزّن النص الخام
            try:
                response_body = resp.json()
            except Exception:
                response_body = {"text": resp.text[:5000]}  # لا نخزن نصوص كبيرة جداً
        except httpx.RequestError as exc:
            error_message = str(exc)
        except Exception as exc:
            error_message = f"Unexpected error: {exc}"

        end_ns = time.monotonic_ns()
        execution_time_ms = int((end_ns - start_ns) / 1_000_000)

        log = cls.log_call(
            db=db,
            service=service,
            endpoint=endpoint,
            http_method=method,
            request_headers=headers,
            request_body=request_body,
            response_status=response_status,
            response_headers=response_headers,
            response_body=response_body,
            execution_time_ms=execution_time_ms,
            error_message=error_message,
        )

        return log
