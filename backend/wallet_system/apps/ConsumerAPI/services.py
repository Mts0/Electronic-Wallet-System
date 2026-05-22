import random
import string
from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from . import models, schemas


class APIConsumerService:
    """خدمات إدارة مستهلكي الـ API (api_consumers)."""

    # ---------- Helpers ----------

    @staticmethod
    def _generate_api_key(length: int = 40) -> str:
        chars = string.ascii_letters + string.digits
        return "".join(random.choices(chars, k=length))

    @classmethod
    def _generate_unique_api_key(cls, db: Session) -> str:
        """توليد api_key غير مكرر."""
        while True:
            key = cls._generate_api_key()
            exists = db.scalar(
                select(models.APIConsumer).where(models.APIConsumer.api_key == key)
            )
            if not exists:
                return key

    # ---------- CRUD Consumers ----------

    @staticmethod
    def list_consumers(db: Session) -> List[models.APIConsumer]:
        return list(
            db.scalars(
                select(models.APIConsumer)
                .order_by(models.APIConsumer.created_at.desc())
            )
        )

    @staticmethod
    def get_consumer_by_id(
        db: Session, consumer_id: int
    ) -> Optional[models.APIConsumer]:
        return db.get(models.APIConsumer, consumer_id)

    @staticmethod
    def get_consumer_by_key(
        db: Session, api_key: str
    ) -> Optional[models.APIConsumer]:
        return db.scalar(
            select(models.APIConsumer).where(models.APIConsumer.api_key == api_key)
        )

    @classmethod
    def create_consumer(
        cls, db: Session, data: schemas.APIConsumerCreate
    ) -> models.APIConsumer:
        api_key = cls._generate_unique_api_key(db)

        consumer = models.APIConsumer(
            name=data.name,
            api_key=api_key,
            allowed_ips=data.allowed_ips,
            allowed_endpoints=data.allowed_endpoints,
            is_active=data.is_active,
            created_at=datetime.utcnow(),
        )
        db.add(consumer)
        db.commit()
        db.refresh(consumer)
        return consumer

    @staticmethod
    def update_consumer(
        db: Session,
        consumer: models.APIConsumer,
        data: schemas.APIConsumerUpdate,
    ) -> models.APIConsumer:
        if data.name is not None:
            consumer.name = data.name
        if data.allowed_ips is not None:
            consumer.allowed_ips = data.allowed_ips
        if data.allowed_endpoints is not None:
            consumer.allowed_endpoints = data.allowed_endpoints
        if data.is_active is not None:
            consumer.is_active = data.is_active

        db.add(consumer)
        db.commit()
        db.refresh(consumer)
        return consumer

    @staticmethod
    def set_consumer_active(
        db: Session, consumer: models.APIConsumer, is_active: bool
    ) -> models.APIConsumer:
        consumer.is_active = is_active
        db.add(consumer)
        db.commit()
        db.refresh(consumer)
        return consumer

    # ---------- API Key Rotation ----------

    @classmethod
    def rotate_api_key(
        cls,
        db: Session,
        consumer: models.APIConsumer,
        changed_by_staff_id: int,
    ) -> models.APIKeysUpdate:
        old_key = consumer.api_key
        new_key = cls._generate_unique_api_key(db)

        consumer.api_key = new_key
        db.add(consumer)

        record = models.APIKeysUpdate(
            consumer_id=consumer.consumer_id,
            old_api_key=old_key,
            new_api_key=new_key,
            changed_by=changed_by_staff_id,
            changed_at=datetime.utcnow(),
        )
        db.add(record)
        db.commit()
        db.refresh(record)
        return record

    # ---------- Logs ----------

    @staticmethod
    def log_access(
        db: Session,
        consumer: models.APIConsumer,
        endpoint: str,
        http_method: str,
        request_body: Optional[dict],
        response_status: Optional[int],
        ip_address: Optional[str],
        user_agent: Optional[str],
    ) -> "models.APIAccessLog":
        log = models.APIAccessLog(
            consumer_id=consumer.consumer_id,
            endpoint=endpoint,
            http_method=http_method,
            request_body=request_body,
            response_status=response_status,
            ip_address=ip_address,

            created_at=datetime.utcnow(),
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        return log

    @staticmethod
    def list_consumer_logs(
        db: Session, consumer_id: int, limit: int = 100
    ) -> List["models.APIAccessLog"]:
        return list(
            db.scalars(
                select(models.APIAccessLog)
                .where(models.APIAccessLog.consumer_id == consumer_id)
                .order_by(models.APIAccessLog.created_at.desc())
                .limit(limit)
            )
        )
