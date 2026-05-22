# Favorites/schemas.py

from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, Field


# ========= Favorite Contacts =========

class FavoriteContactBase(BaseModel):
    name: str = Field(..., max_length=100)
    phone_number: str = Field(..., max_length=20)


class FavoriteContactCreate(FavoriteContactBase):
    pass


class FavoriteContactUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)


class FavoriteContactOut(BaseModel):
    fc_id: int
    user_id: int
    name: str
    phone_number: str
    created_at: datetime

    class Config:
        from_attributes = True


# ========= Favorite Transfers =========

class FavoriteTransferBase(BaseModel):
    wallet_number: str = Field(..., max_length=50)
    name: str


class FavoriteTransferCreate(FavoriteTransferBase):
    pass


class FavoriteTransferUpdate(BaseModel):
    wallet_number: Optional[str] = Field(None, max_length=50)
    name: str


class FavoriteTransferOut(BaseModel):
    ft_id: int
    user_id: int
    wallet_number: str
    created_at: datetime

    class Config:
        from_attributes = True


# ========= Favorite Internet =========

class FavoriteInternetBase(BaseModel):
    name: str = Field(..., max_length=100)


class FavoriteInternetCreate(FavoriteInternetBase):
    pass


class FavoriteInternetUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)


class FavoriteInternetOut(BaseModel):
    fi_id: int
    user_id: int
    name: str
    subcription_number: int
    created_at: datetime

    class Config:
        from_attributes = True


# ========= Generic =========

class MessageResponse(BaseModel):
    message: str
