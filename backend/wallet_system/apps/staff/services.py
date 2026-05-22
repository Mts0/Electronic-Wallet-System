from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select, and_, delete

from . import models, schemas
from ..auth import models as auth_models  # تأكد من المسار حسب مشروعك


class StaffService:
    # ===== STAFF CRUD =====

    @staticmethod
    def get_staff_by_id(db: Session, staff_id: int) -> Optional[models.Staff]:
        return db.get(models.Staff, staff_id)

    @staticmethod
    def get_staff_by_user_id(db: Session, user_id: int) -> Optional[models.Staff]:
        return db.scalar(
            select(models.Staff).where(models.Staff.user_id == user_id)
        )

    @staticmethod
    def list_staff(
        db: Session,
        is_active: Optional[bool] = None,
    ) -> List[models.Staff]:
        stmt = select(models.Staff)
        if is_active is not None:
            stmt = stmt.where(models.Staff.is_active == is_active)
        stmt = stmt.order_by(models.Staff.created_at.asc())
        return list(db.scalars(stmt))

    @staticmethod
    def create_staff(db: Session, data: schemas.StaffCreate) -> models.Staff:
        # تأكد أن المستخدم موجود
        user = db.get(auth_models.User, data.user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="المستخدم غير موجود",
            )

        # تأكد أنه ليس Staff مسبقًا
        existing = StaffService.get_staff_by_user_id(db, data.user_id)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="هذا المستخدم مسجل كموظف مسبقًا",
            )

        # حدّث نوع المستخدم ليصبح STAFF (لو حاب)
        if getattr(user, "user_type", None) != "STAFF":
            user.user_type = "STAFF"
            db.add(user)

        staff = models.Staff(
            user_id=data.user_id,
            monthly_salary=data.monthly_salary,
            hire_date=data.hire_date,
            university_major=data.university_major,
            is_active=data.is_active,
            created_at=datetime.utcnow(),
            updated_at=None,
        )

        db.add(staff)
        db.commit()
        db.refresh(staff)
        return staff

    @staticmethod
    def update_staff(
        db: Session,
        staff: models.Staff,
        data: schemas.StaffUpdate,
    ) -> models.Staff:
        if data.monthly_salary is not None:
            staff.monthly_salary = data.monthly_salary
        if data.university_major is not None:
            staff.university_major = data.university_major
        if data.is_active is not None:
            staff.is_active = data.is_active

        staff.updated_at = datetime.utcnow()
        db.add(staff)
        db.commit()
        db.refresh(staff)
        return staff

    @staticmethod
    def set_staff_active(
        db: Session,
        staff: models.Staff,
        is_active: bool,
    ) -> models.Staff:
        staff.is_active = is_active
        staff.updated_at = datetime.utcnow()
        db.add(staff)
        db.commit()
        db.refresh(staff)
        return staff

    # ===== ROLES =====


    @staticmethod
    def delete_role(db: Session, role: models.Role) -> None:
        # احذف الربوطات أولاً (مهم لأن role_permissions عندك ما عليها ondelete="CASCADE")
        db.execute(delete(models.RolePermission).where(models.RolePermission.role_id == role.role_id))
        db.execute(delete(models.StaffRole).where(models.StaffRole.role_id == role.role_id))

        db.delete(role)
        db.commit()


    @staticmethod
    def get_role_by_id(db: Session, role_id: int) -> Optional[models.Role]:
        return db.get(models.Role, role_id)

    @staticmethod
    def get_role_by_name(db: Session, name: str) -> Optional[models.Role]:
        return db.scalar(select(models.Role).where(models.Role.name == name))

    @staticmethod
    def list_roles(db: Session) -> List[models.Role]:
        return list(db.scalars(select(models.Role).order_by(models.Role.created_at.desc())))

    @staticmethod
    def create_role(db: Session, data: schemas.RoleCreate) -> models.Role:
        existing = StaffService.get_role_by_name(db, data.name)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="اسم الدور مستخدم مسبقًا",
            )

        role = models.Role(
            name=data.name,
            created_at=datetime.utcnow(),
        )
        db.add(role)
        db.commit()
        db.refresh(role)
        return role

    @staticmethod
    def update_role(
        db: Session,
        role: models.Role,
        data: schemas.RoleUpdate,
    ) -> models.Role:
        if data.name is not None and data.name != role.name:
            # تأكد أنه لا يوجد دور بنفس الاسم
            existing = StaffService.get_role_by_name(db, data.name)
            if existing and existing.role_id != role.role_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="اسم الدور مستخدم مسبقًا",
                )
            role.name = data.name

        db.add(role)
        db.commit()
        db.refresh(role)
        return role

    # ===== PERMISSIONS =====

    @staticmethod
    def get_permission_by_id(
        db: Session, permission_id: int
    ) -> Optional[models.Permission]:
        return db.get(models.Permission, permission_id)

    @staticmethod
    def get_permission_by_name(
        db: Session, name: str
    ) -> Optional[models.Permission]:
        return db.scalar(
            select(models.Permission).where(models.Permission.name == name)
        )

    @staticmethod
    def list_permissions(db: Session) -> List[models.Permission]:
        return list(
            db.scalars(
                select(models.Permission).order_by(models.Permission.created_at.desc())
            )
        )

    @staticmethod
    def create_permission(
        db: Session, data: schemas.PermissionCreate
    ) -> models.Permission:
        existing = StaffService.get_permission_by_name(db, data.name)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="اسم الصلاحية مستخدم مسبقًا",
            )

        perm = models.Permission(
            name=data.name,
            description=data.description,
            created_at=datetime.utcnow(),
        )
        db.add(perm)
        db.commit()
        db.refresh(perm)
        return perm

    # ===== ROLE <-> PERMISSION =====

    @staticmethod
    def assign_permission_to_role(
        db: Session, role: models.Role, permission: models.Permission
    ) -> models.RolePermission:
        existing = db.scalar(
            select(models.RolePermission).where(
                models.RolePermission.role_id == role.role_id,
                models.RolePermission.permission_id == permission.permission_id,
            )
        )
        if existing:
            return existing

        rp = models.RolePermission(
            role_id=role.role_id,
            permission_id=permission.permission_id,
            granted_at=datetime.utcnow(),
        )
        db.add(rp)
        db.commit()
        db.refresh(rp)
        return rp

    @staticmethod
    def remove_permission_from_role(
        db: Session, role: models.Role, permission: models.Permission
    ) -> None:
        rp = db.scalar(
            select(models.RolePermission).where(
                models.RolePermission.role_id == role.role_id,
                models.RolePermission.permission_id == permission.permission_id,
            )
        )
        if not rp:
            return

        db.delete(rp)
        db.commit()

    # ===== STAFF <-> ROLES =====

    @staticmethod
    def assign_role_to_staff(
        db: Session, staff: models.Staff, role: models.Role
    ) -> models.StaffRole:
        existing = db.scalar(
            select(models.StaffRole).where(
                models.StaffRole.staff_id == staff.staff_id,
                models.StaffRole.role_id == role.role_id,
            )
        )
        if existing:
            return existing

        sr = models.StaffRole(
            staff_id=staff.staff_id,
            role_id=role.role_id,
            assigned_at=datetime.utcnow(),
        )
        db.add(sr)
        db.commit()
        db.refresh(sr)
        return sr

    @staticmethod
    def remove_role_from_staff(
        db: Session, staff: models.Staff, role: models.Role
    ) -> None:
        sr = db.scalar(
            select(models.StaffRole).where(
                models.StaffRole.staff_id == staff.staff_id,
                models.StaffRole.role_id == role.role_id,
            )
        )
        if not sr:
            return
        db.delete(sr)
        db.commit()

    @staticmethod
    def get_staff_roles(
        db: Session, staff: models.Staff
    ) -> List[models.Role]:
        stmt = (
            select(models.Role)
            .join(models.StaffRole)
            .where(models.StaffRole.staff_id == staff.staff_id)
        )
        return list(db.scalars(stmt))

    @staticmethod
    def get_staff_permissions(
        db: Session, staff: models.Staff
    ) -> List[models.Permission]:
        # permissions المرتبطة بأدوار هذا الموظف
        stmt = (
            select(models.Permission)
            .join(models.RolePermission)
            .join(models.Role)
            .join(models.StaffRole)
            .where(models.StaffRole.staff_id == staff.staff_id)
        )
        # ممكن تستخدم DISTINCT لو الـ DB يدعم
        perms = list(db.scalars(stmt))
        # إزالة التكرار في البايثون
        unique = {p.permission_id: p for p in perms}
        return list(unique.values())

    # ===== USER LIMITS =====

    @staticmethod
    def change_user_limit(
        db: Session,
        payload: schemas.UserLimitChange,
        changed_by_staff: models.Staff,
    ) -> models.UserLimit:
        user = db.get(auth_models.User, payload.user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="المستخدم غير موجود",
            )

        # تحديد العمود الهدف
        if payload.type == schemas.LimitType.DAILY:
            field_name = "daily_limit"
        else:
            field_name = "monthly_limit"

        old_value = getattr(user, field_name, None)
        new_value = float(payload.new_limit)

        setattr(user, field_name, new_value)
        db.add(user)

        record = models.UserLimit(
            user_id=user.user_id,
            old_limit=old_value,
            new_limit=new_value,
            type=payload.type.value,
            changed_by=changed_by_staff.staff_id,
            changed_at=datetime.utcnow(),
        )

        db.add(record)
        db.commit()
        db.refresh(record)
        return record
