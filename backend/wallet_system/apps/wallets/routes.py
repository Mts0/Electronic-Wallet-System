# apps/wallets/routes.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..auth.services import UserService
from ..core.database import get_session
from ..auth.dependencies import get_current_active_user
from . import schemas, models
from .services import WalletService
from .dependencies import get_current_user_wallet, get_current_user_wallet_account
from ..staff.dependencies import require_permission
from decimal import Decimal

router = APIRouter(prefix="/wallets", tags=["Wallets"])


# ====== Get my wallet + accounts ======

@router.get("/me", response_model=schemas.WalletOut)
def get_my_wallet(
        wallet: models.Wallet = Depends(get_current_user_wallet),
        db: Session = Depends(get_session),
):
    # نضمن تحميل الحسابات + العملات
    wallet = WalletService.get_wallet_by_user_id(db, wallet.user_id)
    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="لم يتم العثور على المحفظة",
        )
    return wallet


@router.get("/me/accounts", response_model=list[schemas.WalletAccountOut])
def get_my_wallet_accounts(
        wallet: models.Wallet = Depends(get_current_user_wallet),
        db: Session = Depends(get_session),
):
    accounts = WalletService.list_wallet_accounts(db, wallet.wallet_id)
    return accounts


# ====== Create new wallet account (add currency to user's wallet) ======

@router.post(
    "/me/accounts",
    response_model=schemas.WalletAccountOut,
    status_code=status.HTTP_201_CREATED,
)
def create_wallet_account_for_me(
        payload: schemas.WalletAccountCreate,
        wallet: models.Wallet = Depends(get_current_user_wallet),
        db: Session = Depends(get_session),
):
    # تأكد من وجود العملة وأنها مفعلة
    currency = WalletService.get_currency_by_id(db, payload.currency_id)
    if not currency or not currency.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="العملة غير موجودة أو غير مفعّلة",
        )

    account = WalletService.create_wallet_account(
        db=db,
        wallet=wallet,
        currency=currency,
        initial_balance=float(payload.initial_balance or 0),
    )
    return account


# ====== Update wallet account status (مثلاً تجميد الحساب) ======

@router.patch(
    "/me/accounts/{account_id}/status",
    response_model=schemas.WalletAccountOut,
)
def update_my_wallet_account_status(
        account_id: int,
        payload: schemas.WalletAccountUpdateStatus,
        account: models.WalletAccount = Depends(get_current_user_wallet_account),
        db: Session = Depends(get_session),
):
    # ممكن تضيف منطق: لا يسمح بإغلاق حساب فيه رصيد > 0 ... الخ
    updated = WalletService.change_wallet_account_status(
        db=db,
        account=account,
        status=payload.status,
    )
    return updated


# ====== (اختيارية) قائمة العملات الفعّالة ======

@router.get("/currencies", response_model=list[schemas.CurrencyOut])
def list_active_currencies(
        db: Session = Depends(get_session),
):
    currencies = WalletService.list_active_currencies(db)
    return currencies


# اضافات جديدة

@router.post("/master/create",response_model=schemas.WalletOut, status_code=status.HTTP_201_CREATED,)
def create_master_wallet(

        db: Session = Depends(get_session),
        current_staff=Depends(require_permission("manage_master_wallet")),
):
    system_user = WalletService.create_system_user(db)
    wallet = WalletService.create_master_wallet(db, system_user.user_id)
    WalletService.ensure_default_accounts(db, wallet, currency_ids=[1, 2, 3])
    db.commit()
    db.refresh(wallet)
    return wallet


@router.post("/master/initial-funding",
             response_model=schemas.InitialFundingOut, status_code=status.HTTP_201_CREATED)
def initial_funding(
        payload: schemas.InitialFundingCreate,
        db: Session = Depends(get_session),
        current_staff=Depends(require_permission("manage_master_wallet")),
):
    account = WalletService.initial_funding(
        db=db,
        currency_id=payload.currency_id,
        amount=Decimal(str(payload.amount)),
    )
    db.commit()
    db.refresh(account)
    return schemas.InitialFundingOut(
        message="تم التمويل الافتتاحي بنجاح",
        wallet_id=account.wallet_id,
        account_id=account.account_id,
        currency_id=account.currency_id,
        amount=Decimal(str(payload.amount)),
        balance=Decimal(str(account.balance)),
    )
