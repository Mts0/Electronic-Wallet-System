from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_staff_user
from ..auth import models as auth_models

from . import models, schemas
from .services import StaffService
from .dependencies import get_current_staff, require_permission

router = APIRouter(prefix="/staff", tags=["staff & roles"])


# ========= STAFF SELF / ME =========

@router.get("/me", response_model=schemas.StaffMeOut)
def get_my_staff_profile(
    db: Session = Depends(get_session),
    staff: models.Staff = Depends(get_current_staff),
):
    roles = StaffService.get_staff_roles(db, staff)
    perms = StaffService.get_staff_permissions(db, staff)
    return schemas.StaffMeOut(
        staff=staff,
        roles=roles,
        permissions=perms,
    )


# ========= ROLES =========

@router.get(
    "/roles",
    response_model=List[schemas.RoleOut],
)
def list_roles(
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("view_roles")),
):
    roles = StaffService.list_roles(db)
    return roles


@router.post(
    "/roles",
    response_model=schemas.RoleOut,
    status_code=status.HTTP_201_CREATED,
)
def create_role(
    payload: schemas.RoleCreate,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("manage_roles")),
):
    role = StaffService.create_role(db, payload)
    return role


@router.patch(
    "/roles/{role_id}",
    response_model=schemas.RoleOut,
)
def update_role(
    role_id: int,
    payload: schemas.RoleUpdate,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("manage_roles")),
):
    role = StaffService.get_role_by_id(db, role_id)
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الدور غير موجود",
        )
    role = StaffService.update_role(db, role, payload)
    return role


@router.delete(
    "/roles/{role_id}",
    response_model=schemas.MessageResponse,
)
def delete_role(
    role_id: int,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("manage_roles")),
):
    role = StaffService.get_role_by_id(db, role_id)
    if not role:
        raise HTTPException(status_code=404, detail="الدور غير موجود")

    StaffService.delete_role(db, role)
    return schemas.MessageResponse(message="تم حذف الدور بنجاح")



# ========= PERMISSIONS =========

@router.get(
    "/permissions",
    response_model=List[schemas.PermissionOut],
)
def list_permissions(
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("view_permissions")),
):
    perms = StaffService.list_permissions(db)
    return perms


@router.post(
    "/permissions",
    response_model=schemas.PermissionOut,
    status_code=status.HTTP_201_CREATED,
)
def create_permission(
    payload: schemas.PermissionCreate,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("manage_permissions")),
):
    perm = StaffService.create_permission(db, payload)
    return perm



# ========= STAFF MANAGEMENT =========

@router.get(
    "",
    response_model=List[schemas.StaffOut],
)
def list_staff(
    is_active: bool | None = None,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("view_staff")),
):
    staff_list = StaffService.list_staff(db, is_active=is_active)
    return staff_list


from typing import List, Optional
from fastapi import Query
from sqlalchemy import select
from apps.auth import models as auth_models
from apps.auth import schemas as auth_schemas

@router.get(
    "/users",
    response_model=List[auth_schemas.UserResponse],
)
def list_users(
    user_type: Optional[auth_schemas.UserType] = Query(None),  # CUSTOMER / STAFF
    is_active: Optional[bool] = Query(None),
    q: Optional[str] = Query(None, description="بحث بالاسم/الهاتف/الإيميل"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("view_users")),
):
    stmt = select(auth_models.User).where(auth_models.User.user_type != "SYSTEM").order_by(auth_models.User.user_id.asc())

    if user_type:
        stmt = stmt.where(auth_models.User.user_type == user_type.value)

    if is_active is not None:
        stmt = stmt.where(auth_models.User.is_active == is_active)

    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(
            (auth_models.User.full_name.ilike(like)) |
            (auth_models.User.phone_number.ilike(like)) |
            (auth_models.User.email.ilike(like))
        )

    stmt = stmt.order_by(auth_models.User.user_id.desc()).limit(limit).offset(offset)
    return db.execute(stmt).scalars().all()








@router.post(
    "/create",
    response_model=schemas.StaffOut,
    status_code=status.HTTP_201_CREATED,
)
def create_staff(
    payload: schemas.StaffCreate,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("create_staff")),
):
    staff = StaffService.create_staff(db, payload)
    return staff


@router.get(
    "/{staff_id}",
    response_model=schemas.StaffOut,
)
def get_staff_by_id(
    staff_id: int,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("view_staff")),
):
    staff = StaffService.get_staff_by_id(db, staff_id)
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الموظف غير موجود",
        )
    return staff


@router.patch(
    "/{staff_id}",
    response_model=schemas.StaffOut,
)
def update_staff(
    staff_id: int,
    payload: schemas.StaffUpdate,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("edit_staff")),
):
    staff = StaffService.get_staff_by_id(db, staff_id)
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الموظف غير موجود",
        )
    staff = StaffService.update_staff(db, staff, payload)
    return staff


@router.post(
    "/{staff_id}/activate",
    response_model=schemas.StaffOut,
)
def activate_staff(
    staff_id: int,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("edit_staff")),
):
    staff = StaffService.get_staff_by_id(db, staff_id)
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الموظف غير موجود",
        )
    staff = StaffService.set_staff_active(db, staff, True)
    return staff


@router.post(
    "/{staff_id}/deactivate",
    response_model=schemas.StaffOut,
)
def deactivate_staff(
    staff_id: int,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("edit_staff")),
):
    staff = StaffService.get_staff_by_id(db, staff_id)
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الموظف غير موجود",
        )
    staff = StaffService.set_staff_active(db, staff, False)
    return staff








# ========= ROLE <-> PERMISSION =========

@router.post(
    "/roles/{role_id}/permissions/{permission_id}",
    response_model=schemas.MessageResponse,
)
def attach_permission_to_role(
    role_id: int,
    permission_id: int,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("manage_roles")),
):
    role = StaffService.get_role_by_id(db, role_id)
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الدور غير موجود",
        )
    perm = StaffService.get_permission_by_id(db, permission_id)
    if not perm:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الصلاحية غير موجودة",
        )

    StaffService.assign_permission_to_role(db, role, perm)
    return schemas.MessageResponse(message="تم ربط الصلاحية بالدور بنجاح")


@router.delete(
    "/roles/{role_id}/permissions/{permission_id}",
    response_model=schemas.MessageResponse,
)
def detach_permission_from_role(
    role_id: int,
    permission_id: int,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("manage_roles")),
):
    role = StaffService.get_role_by_id(db, role_id)
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الدور غير موجود",
        )
    perm = StaffService.get_permission_by_id(db, permission_id)
    if not perm:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الصلاحية غير موجودة",
        )

    StaffService.remove_permission_from_role(db, role, perm)
    return schemas.MessageResponse(message="تم إزالة الصلاحية من الدور بنجاح")


# ========= STAFF <-> ROLES =========

@router.post(
    "/{staff_id}/roles/{role_id}",
    response_model=schemas.MessageResponse,
)
def assign_role_to_staff(
    staff_id: int,
    role_id: int,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("manage_staff_roles")),
):
    staff = StaffService.get_staff_by_id(db, staff_id)
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الموظف غير موجود",
        )
    role = StaffService.get_role_by_id(db, role_id)
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الدور غير موجود",
        )

    StaffService.assign_role_to_staff(db, staff, role)
    return schemas.MessageResponse(message="تم ربط الدور بالموظف بنجاح")


@router.delete(
    "/{staff_id}/roles/{role_id}",
    response_model=schemas.MessageResponse,
)
def remove_role_from_staff(
    staff_id: int,
    role_id: int,
    db: Session = Depends(get_session),
    current_staff: models.Staff = Depends(require_permission("manage_staff_roles")),
):
    staff = StaffService.get_staff_by_id(db, staff_id)
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الموظف غير موجود",
        )
    role = StaffService.get_role_by_id(db, role_id)
    if not role:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="الدور غير موجود",
        )

    StaffService.remove_role_from_staff(db, staff, role)
    return schemas.MessageResponse(message="تم إزالة الدور من الموظف بنجاح")


# ========= USER LIMITS =========

@router.post(
    "/user-limits/change",
    response_model=schemas.UserLimitOut,
)
def change_user_limit(
    payload: schemas.UserLimitChange,
    db: Session = Depends(get_session),
    staff: models.Staff = Depends(require_permission("change_user_limit")),
):
    record = StaffService.change_user_limit(db, payload, staff)
    return record
