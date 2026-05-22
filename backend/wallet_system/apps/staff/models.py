from sqlalchemy import Column, Integer,CheckConstraint ,String,Text,Boolean, DateTime, Float, Date,DECIMAL, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime, date
from ..core.database import Base


class Staff(Base):
    __tablename__ = "staff"

    staff_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), unique=True, nullable=False)
    monthly_salary = Column(DECIMAL(10,2), nullable=False)
    hire_date = Column(Date, nullable=False)
    university_major = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime)


    user = relationship("User")
    roles = relationship("StaffRole", back_populates="staff")

    api_keys_updates = relationship("APIKeysUpdate", back_populates="changed_by_staff")


class Role(Base):
    __tablename__ = "roles"

    role_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


    permissions = relationship("RolePermission", back_populates="role")


    staff_roles = relationship("StaffRole", back_populates="role")


class StaffRole(Base):
    __tablename__ = "staff_roles"

    sr_id = Column(Integer, primary_key=True, autoincrement=True)
    staff_id = Column(Integer, ForeignKey("staff.staff_id", ondelete="CASCADE"), nullable=False)
    role_id = Column(Integer, ForeignKey("roles.role_id", ondelete="CASCADE"), nullable=False)
    assigned_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('staff_id', 'role_id', name='idx_stfID_rolID'),
    )

    staff = relationship("Staff", back_populates="roles")
    role = relationship("Role", back_populates="staff_roles")


class Permission(Base):
    __tablename__ = "permissions"

    permission_id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)


class RolePermission(Base):
    __tablename__ = "role_permissions"

    rp_id = Column(Integer, primary_key=True, autoincrement=True)
    role_id = Column(Integer, ForeignKey("roles.role_id"), nullable=False)
    permission_id = Column(Integer, ForeignKey("permissions.permission_id"), nullable=False)
    granted_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint('role_id', 'permission_id', name='idx_rolID_permsionID'),
    )

    role = relationship("Role", back_populates="permissions")
    permission = relationship("Permission")


class UserLimit(Base):
    __tablename__ = "user_limits"

    limit_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    old_limit = Column(DECIMAL(9,2))
    new_limit = Column(DECIMAL(9,2))
    type = Column(Text)
    changed_by = Column(Integer, ForeignKey("staff.staff_id"), nullable=False)
    changed_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
            CheckConstraint("type IN('daily_limit','monthly_limit')",name="type_limit"),
    )

    user = relationship("User")
    changed_by_staff = relationship("Staff")