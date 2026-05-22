from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base


class FavoriteContact(Base):
    __tablename__ = "favorite_contacts"

    fc_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    name = Column(String(100), nullable=False)
    phone_number = Column(String(20), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")


class FavoriteTransfer(Base):
    __tablename__ = "favorite_transfers"
    
    ft_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    wallet_number = Column(String(50), nullable=False)
    name = Column(String,nullable=False)
    #notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")


class FavoriteInternet(Base):
    __tablename__ = "favorite_internet"

    fi_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    name = Column(String(40), nullable=False)
    subcription_number = Column(String(30),nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")