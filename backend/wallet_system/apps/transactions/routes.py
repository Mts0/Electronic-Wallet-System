# apps/transactions/routes.py

from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user, get_current_kyc_verified_user
from . import schemas, models
from .services import TransactionService
from .dependencies import get_user_transaction_by_id
from ..staff.dependencies import require_permission
from ..wallets.services import WalletService
from ..ExchangeRates.services import ExchangeRateService

router = APIRouter(prefix="/transactions", tags=["Transcations"])


# ===== قائمة العمليات الخاصة بالمستخدم =====

@router.get("/me", response_model=List[schemas.TransactionOut])
def list_my_transactions(
        limit: int = Query(50, ge=1, le=200),
        status_filter: Optional[schemas.TransactionStatus] = Query(None),
        type_filter: Optional[schemas.TransactionType] = Query(None),
        db: Session = Depends(get_session),
        current_user=Depends(get_current_kyc_verified_user),
):
    txs = TransactionService.list_user_transactions(
        db=db,
        user_id=current_user.user_id,
        limit=limit,
        status_filter=status_filter,
        type_filter=type_filter,
    )
    return txs


@router.get(
    "/me/{transaction_id}",
    response_model=schemas.TransactionOut,
)
def get_my_transaction(
        transaction: models.Transaction = Depends(get_user_transaction_by_id),
):
    return transaction


# ===== تحويل بين المحافظ =====

@router.post(
    "/transfer",
    response_model=schemas.TransferOut,
    status_code=status.HTTP_201_CREATED,
)
def create_transfer(
        payload: schemas.TransferCreate,
        db: Session = Depends(get_session),
        current_user=Depends(get_current_kyc_verified_user),
):
    tx = TransactionService.create_transfer(db=db, user_id=current_user.user_id, data=payload)
    return tx


# ===== شحن رصيد =====

"""@router.post(
    "/topup",
    response_model=schemas.TransactionOut,
    status_code=status.HTTP_201_CREATED,
)
def create_topup(
    payload: schemas.TopupCreate,
    db: Session = Depends(get_session),
    current_user=Depends(get_current_kyc_verified_user),
):
    tx = TransactionService.create_topup(db=db, user_id=current_user.user_id, data=payload)
    return tx"""


# ===== إيداع للمحفظة (CASH-IN) =====
@router.post(
    "/cash-in",
    response_model=schemas.CashInOut,
    status_code=status.HTTP_201_CREATED,
)
def create_cash_in(
        payload: schemas.CashInCreate,
        db: Session = Depends(get_session),
        current_staff=Depends(require_permission("wallet_cash_in")),
):
    return TransactionService.create_cash_in(
        db=db,
        staff_user_id=current_staff.user_id,
        data=payload,
    )




@router.post(
    "/cash-deposit",
    response_model=schemas.CashDepositOut,
    status_code=status.HTTP_201_CREATED,
)
def create_cash_deposit(
        payload: schemas.CashDepositCreate,
        db: Session = Depends(get_session),
        current_staff=Depends(require_permission("wallet_cash_deposit")),
):
    return TransactionService.create_cash_deposit(
        db=db,
        staff_id=current_staff.user_id,
        data=payload,
    )


"""@router.post(
    "/cash-deposit",
    response_model=schemas.CashDepositOut,
    status_code=status.HTTP_201_CREATED,
)
def create_cash_deposit(
        payload: schemas.CashDepositCreate,
        db: Session = Depends(get_session),
        current_staff=Depends(require_permission("wallet_cash_deposit")),
):
    return TransactionService.create_cash_deposit(
        db=db,
        staff_id=current_staff.staff_id,
        data=payload,
    )"""


# ===== شحن رصيد هاتف (MOBILE TOPUP) =====
@router.post(
    "/mobile-topup",
    response_model=schemas.TopupOut,
    status_code=status.HTTP_201_CREATED,
)
def create_mobile_topup(
        payload: schemas.TopupCreate,  # نستخدم TopupCreate الحالي لأنه فيه phone_number
        db: Session = Depends(get_session),
        current_user=Depends(get_current_kyc_verified_user),
):
    return TransactionService.create_mobile_topup(db=db, user_id=current_user.user_id, data=payload)


# ===== صرف عملة (Exchange) =====


@router.post(
    "/exchange",
    response_model=schemas.ExchangeOut,
    status_code=status.HTTP_201_CREATED,
)
def create_exchange(
        payload: schemas.ExchangeCreate,
        db: Session = Depends(get_session),
        current_user=Depends(get_current_kyc_verified_user),
):
    tx = TransactionService.create_exchange(
        db=db,
        user_id=current_user.user_id,
        data=payload,
    )
    return tx


# ===== طلب سحب من الصراف =====

@router.post(
    "/atm-withdraw",
    response_model=schemas.ATMWithdrawOut,
    status_code=status.HTTP_201_CREATED,
)
def create_atm_withdraw_request(
        payload: schemas.ATMWithdrawCreate,
        db: Session = Depends(get_session),
        current_user=Depends(get_current_kyc_verified_user),
):
    req = TransactionService.create_atm_withdraw_request(
        db=db,
        user_id=current_user.user_id,
        data=payload,
    )
    return req


@router.get("/me/failed", response_model=List[schemas.TransactionOut])
def list_my_failed_transactions(
        limit: int = Query(50, ge=1, le=200),
        db: Session = Depends(get_session),
        current_user=Depends(get_current_kyc_verified_user),
):
    """اختصار: يرجع العمليات التي status=FAILED.

    تقدر تعمل نفس الشي عبر /me?status_filter=FAILED، لكن هذا المسار أسهل للاستخدام.
    """
    return TransactionService.list_user_transactions(
        db=db,
        user_id=current_user.user_id,
        limit=limit,
        status_filter=schemas.TransactionStatus.FAILED,
    )
