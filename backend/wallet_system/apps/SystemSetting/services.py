# SystemSetting/services.py

from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from . import models, schemas


class SystemSettingService:
    """
    منطق إدارة:
    - system_settings
    - settings_update
    """

    # ===== Getters =====

    @staticmethod
    def list_settings(
        db: Session,
        is_public: Optional[bool] = None,
    ) -> List[models.SystemSetting]:
        stmt = select(models.SystemSetting)
        if is_public is not None:
            stmt = stmt.where(models.SystemSetting.is_public == is_public)

        stmt = stmt.order_by(models.SystemSetting.setting_name.asc())
        return list(db.scalars(stmt))

    @staticmethod
    def list_public_settings(
        db: Session,
    ) -> List[models.SystemSetting]:
        return SystemSettingService.list_settings(db, is_public=True)

    @staticmethod
    def get_setting_by_id(
        db: Session, setting_id: int
    ) -> Optional[models.SystemSetting]:
        return db.get(models.SystemSetting, setting_id)

    @staticmethod
    def get_setting_by_name(
        db: Session, setting_name: str
    ) -> Optional[models.SystemSetting]:
        return db.scalar(
            select(models.SystemSetting).where(
                models.SystemSetting.setting_name == setting_name
            )
        )

    # ===== Create / Update =====

    @classmethod
    def create_setting(
        cls,
        db: Session,
        payload: schemas.SystemSettingCreate,
        staff_id: int,
    ) -> models.SystemSetting:
        # تأكد من عدم تكرار الاسم
        existing = cls.get_setting_by_name(db, payload.setting_name)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="setting_name مستخدم مسبقًا",
            )

        setting = models.SystemSetting(
            setting_name=payload.setting_name,
            setting_value=payload.setting_value,
            description=payload.description,
            is_public=payload.is_public,
            updated_by=staff_id,
            updated_at=datetime.utcnow(),
        )
        db.add(setting)
        db.commit()
        db.refresh(setting)

        # سجل أول إدخال في history
        update_log = models.SettingsUpdate(
            setting_id=setting.setting_id,
            old_value=None,
            new_value=payload.setting_value,
            changed_by=staff_id,
            changed_at=datetime.utcnow(),
        )
        db.add(update_log)
        db.commit()

        return setting

    @classmethod
    def update_setting(
        cls,
        db: Session,
        setting: models.SystemSetting,
        payload: schemas.SystemSettingUpdate,
        staff_id: int,
    ) -> models.SystemSetting:
        old_value = setting.setting_value

        # تحديث الحقول
        if payload.setting_name is not None:
            # [اختياري] تحقق من عدم تكرار الاسم مع إعدادات أخرى
            other = cls.get_setting_by_name(db, payload.setting_name)
            if other and other.setting_id != setting.setting_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="setting_name مستخدم في إعداد آخر",
                )
            setting.setting_name = payload.setting_name

        if payload.setting_value is not None:
            setting.setting_value = payload.setting_value

        if payload.description is not None:
            setting.description = payload.description

        if payload.is_public is not None:
            setting.is_public = payload.is_public

        setting.updated_by = staff_id
        setting.updated_at = datetime.utcnow()

        db.add(setting)
        db.commit()
        db.refresh(setting)

        # سجل التغيير للقيمة فقط (setting_value)
        if payload.setting_value is not None and payload.setting_value != old_value:
            update_log = models.SettingsUpdate(
                setting_id=setting.setting_id,
                old_value=old_value,
                new_value=payload.setting_value,
                changed_by=staff_id,
                changed_at=datetime.utcnow(),
            )
            db.add(update_log)
            db.commit()

        return setting

    # ===== History =====

    @staticmethod
    def list_setting_updates(
        db: Session,
        setting_id: int,
        limit: int = 100,
    ) -> List[models.SettingsUpdate]:
        stmt = (
            select(models.SettingsUpdate)
            .where(models.SettingsUpdate.setting_id == setting_id)
            .order_by(models.SettingsUpdate.changed_at.desc())
            .limit(limit)
        )
        return list(db.scalars(stmt))
