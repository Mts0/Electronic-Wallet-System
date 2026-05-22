from datetime import datetime, timedelta
import random
import string
from decimal import Decimal, ROUND_HALF_UP
from typing import List, Optional
from ..Banking import models as banking_models
from fastapi import HTTPException, status
from sqlalchemy import select, and_
from sqlalchemy.orm import Session, joinedload
from ..staff import models as staff_models
from . import models, schemas
from ..wallets import models as wallet_models
from ..wallets.services import WalletService
from ..ExchangeRates.services import ExchangeRateService
from ..auth import models as auth_models
from ..SystemSetting import models as system_setting_models


class TransactionService:
    """
    Service layer للعمليات المالية (Transactions):
    - إنشاء Transaction رئيسية
    - إنشاء السجلات التفصيلية (transfer/topup/exchange/atm)
    - تسجيل العمليات الفاشلة داخل جدول transactions نفسه (status=FAILED)
      **بدون** الاعتماد على جدول failed_transaction
    - عرض العمليات
    """

    # ========== Helpers عامة ==========

    @staticmethod
    def _generate_ref(prefix: str = "TX") -> str:
        """
        يولد transaction_ref أو code عشوائي بسيط
        """
        body = "".join(random.choices(string.ascii_uppercase + string.digits, k=10))
        return f"{prefix}{body}"

    @staticmethod
    def _get_setting_decimal(db: Session, name: str, default: str = "0.00") -> Decimal:
        setting = db.scalar(
            select(system_setting_models.SystemSetting).where(
                system_setting_models.SystemSetting.setting_name == name
            )
        )

        if not setting:
            return Decimal(default)

        return Decimal(str(setting.setting_value)).quantize(
            Decimal("0.01"),
            rounding=ROUND_HALF_UP
        )

    @staticmethod
    def _total_debit(amount: Decimal, fee: Decimal) -> Decimal:
        return (amount + fee).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    @staticmethod
    def _credit_fee_to_master_wallet(
            db: Session,
            currency_id: int,
            fee: Decimal,
    ):
        if fee <= 0:
            return

        master_account = WalletService.get_master_wallet_account(db, currency_id)
        if not master_account:
            raise HTTPException(
                status_code=500,
                detail="حساب المحفظة الرئيسية غير موجود لاستقبال الرسوم"
            )

        master_account.balance = Decimal(str(master_account.balance)) + fee
        db.add(master_account)
        db.flush()

    # ========== استعلامات عامة ==========

    @staticmethod
    def list_user_transactions(
            db: Session,
            user_id: int,
            limit: int = 50,
            status_filter: Optional[schemas.TransactionStatus] = None,
            type_filter: Optional[schemas.TransactionType] = None,
    ) -> List[models.Transaction]:
        stmt = (
            select(models.Transaction)
            .where(models.Transaction.user_id == user_id)
            .order_by(models.Transaction.created_at.desc())
            .limit(limit)
        )

        if status_filter:
            stmt = stmt.where(models.Transaction.status == status_filter.value)
        if type_filter:
            stmt = stmt.where(models.Transaction.type == type_filter.value)

        return list(db.scalars(stmt))

    @staticmethod
    def get_user_transaction(
            db: Session, user_id: int, transaction_id: int
    ) -> Optional[models.Transaction]:
        return db.scalar(
            select(models.Transaction)
            .where(
                models.Transaction.transaction_id == transaction_id,
                models.Transaction.user_id == user_id,
            )
        )

    # ========== إنشاء Transaction رئيسية ==========

    @staticmethod
    def _create_transaction(
            db: Session,
            user_id: int,
            payload: schemas.TransactionBase,
            tx_type: schemas.TransactionType,
            status: schemas.TransactionStatus = schemas.TransactionStatus.PENDING,
            notes: Optional[str] = None,
    ) -> models.Transaction:
        """ينشئ سجل Transaction داخل نفس الـ Session.

        ملاحظة مهمة:
        - لا نعمل commit هنا لتفادي commits متعددة داخل نفس العملية.
        - نستخدم flush فقط للحصول على transaction_id.
        """
        tx = models.Transaction(
            user_id=user_id,
            currency_id=payload.currency_id,
            amount=payload.amount,
            fee=payload.fee,
            type=tx_type.value,
            status=status.value,
            notes=notes,
            created_at=datetime.utcnow(),
        )
        db.add(tx)
        db.flush()  # للحصول على tx.transaction_id
        return tx

    # ========== فشل العملية داخل transactions (بدون جدول failed_transaction) ==========

    @classmethod
    def _log_failed_tx(
            cls,
            db: Session,
            *,
            user_id: int,
            currency_id: int,
            amount: Decimal,
            tx_type: schemas.TransactionType,
            reason: str,
            notes: Optional[str] = None,
    ) -> models.Transaction:
        base = schemas.TransactionBase(
            amount=amount,
            fee=Decimal("0.00"),
            currency_id=currency_id,
        )
        full_notes = reason if not notes else f"{reason} | {notes}"
        tx = cls._create_transaction(
            db=db,
            user_id=user_id,
            payload=base,
            tx_type=tx_type,
            status=schemas.TransactionStatus.FAILED,
            notes=full_notes,
        )
        return tx

    # ========== تحويل بين المحافظ (TRANSFER) ==========

    @classmethod
    def create_transfer(
            cls,
            db: Session,
            user_id: int,
            data: schemas.TransferCreate,
    ) -> models.Transaction:
        from_account = db.scalar(
            select(wallet_models.WalletAccount)
            .join(wallet_models.Wallet)
            .where(
                wallet_models.WalletAccount.account_id == data.from_account_id,
                wallet_models.Wallet.user_id == user_id,
            )
        )

        if not from_account:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="حساب المرسل غير موجود أو لا يتبع للمستخدم",
            )

        amount = Decimal(str(data.amount))
        currency_id = from_account.currency_id
        fee = cls._get_setting_decimal(db, "internal_transfer_fee", "0.00")
        total_debit = cls._total_debit(amount, fee)

        if from_account.status != "ACTIVE":
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=currency_id,
                amount=amount,
                tx_type=schemas.TransactionType.TRANSFER,
                reason="حساب المرسل غير نشط",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="حساب المرسل غير نشط",
            )

        to_wallet = db.scalar(
            select(wallet_models.Wallet).where(
                wallet_models.Wallet.wallet_number == data.to_wallet_number
            )
        )
        if not to_wallet:
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=currency_id,
                amount=amount,
                tx_type=schemas.TransactionType.TRANSFER,
                reason="محفظة المستلم غير موجودة",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="محفظة المستلم غير موجودة",
            )

        if from_account.wallet_id == to_wallet.wallet_id:
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=currency_id,
                amount=amount,
                tx_type=schemas.TransactionType.TRANSFER,
                reason="لا يمكن التحويل إلى نفس المحفظة",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="لا يمكن التحويل إلى نفس المحفظة",
            )

        if Decimal(str(from_account.balance)) < total_debit:
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=currency_id,
                amount=amount,
                tx_type=schemas.TransactionType.TRANSFER,
                reason="الرصيد غير كافٍ",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="الرصيد غير كافٍ لإتمام العملية",
            )

        to_currency = WalletService.get_currency_by_id(db, currency_id)
        if not to_currency or not to_currency.is_active:
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=currency_id,
                amount=amount,
                tx_type=schemas.TransactionType.TRANSFER,
                reason="العملة غير موجودة أو غير مفعلة",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="العملة غير موجودة أو غير مفعلة",
            )

        to_account = db.scalar(
            select(wallet_models.WalletAccount).where(
                wallet_models.WalletAccount.wallet_id == to_wallet.wallet_id,
                wallet_models.WalletAccount.currency_id == currency_id,
            )
        )
        if not to_account:
            to_account = WalletService.create_wallet_account(
                db=db,
                wallet=to_wallet,
                currency=to_currency,
                initial_balance=0,
            )

        try:
            from_account.balance = Decimal(str(from_account.balance)) - total_debit
            to_account.balance = Decimal(str(to_account.balance)) + amount

            cls._credit_fee_to_master_wallet(db, currency_id, fee)

            base = schemas.TransactionBase(
                amount=amount,
                fee=fee,
                currency_id=currency_id,
            )
            tx = cls._create_transaction(
                db=db,
                user_id=user_id,
                payload=base,
                tx_type=schemas.TransactionType.TRANSFER,
                status=schemas.TransactionStatus.COMPLETED,
                notes=data.notes,
            )

            transfer = models.TransactionTransfer(
                transaction_id=tx.transaction_id,
                from_wallet=from_account.wallet_id,
                to_wallet=to_wallet.wallet_id,
            )
            db.add(transfer)

            db.commit()
            db.refresh(tx)

            receiver_user = db.scalar(
                select(auth_models.User).where(
                    auth_models.User.user_id == to_wallet.user_id
                )
            )

            return schemas.TransferOut(
                transaction=schemas.TransactionOut(
                    transaction_id=tx.transaction_id,
                    user_id=tx.user_id,
                    currency_id=tx.currency_id,
                    amount=tx.amount,
                    fee=tx.fee,
                    type=tx.type,
                    status=tx.status,
                    notes=tx.notes,
                    created_at=tx.created_at,
                ),
                transfers_id=transfer.transfers_id,
                to_wallet_number=to_wallet.wallet_number,
                to_user_name=receiver_user.full_name if receiver_user else None,
            )

        except Exception:
            db.rollback()
            raise

    # ========== شحن نقدي للمحفظة (CASH IN) ==========

    @classmethod
    def create_cash_in(
            cls,
            db: Session,
            staff_user_id: int,
            data: schemas.CashInCreate,
    ):
        wallet = db.scalar(
            select(wallet_models.Wallet).where(
                wallet_models.Wallet.wallet_number == data.wallet_number
            )
        )
        if not wallet:
            raise HTTPException(status_code=400, detail="رقم المحفظة غير موجود")

        account = db.scalar(
            select(wallet_models.WalletAccount).where(
                wallet_models.WalletAccount.wallet_id == wallet.wallet_id,
                wallet_models.WalletAccount.currency_id == data.currency_id,
            )
        )
        if not account:
            raise HTTPException(status_code=400, detail="لا يوجد حساب بهذه العملة داخل المحفظة")

        master_account = WalletService.get_master_wallet_account(db, data.currency_id)
        if not master_account:
            raise HTTPException(status_code=500, detail="حساب master wallet غير موجود")

        amount = Decimal(str(data.amount))

        if Decimal(str(master_account.balance)) < amount:
            raise HTTPException(status_code=400, detail="رصيد master wallet غير كافٍ")

        master_account.balance = Decimal(str(master_account.balance)) - amount
        account.balance = Decimal(str(account.balance)) + amount

        db.add(master_account)
        db.add(account)
        db.flush()

        base = schemas.TransactionBase(
            amount=amount,
            fee=Decimal("0.00"),
            currency_id=data.currency_id,
        )

        tx = cls._create_transaction(
            db=db,
            user_id=wallet.user_id,
            payload=base,
            tx_type=schemas.TransactionType.CASH_IN,
            status=schemas.TransactionStatus.COMPLETED,
            notes=data.notes,
        )

        owner = db.scalar(
            select(auth_models.User).where(auth_models.User.user_id == wallet.user_id)
        )

        db.commit()
        db.refresh(tx)

        return schemas.CashInOut(
            transaction=schemas.TransactionOut(
                transaction_id=tx.transaction_id,
                user_id=tx.user_id,
                currency_id=tx.currency_id,
                amount=tx.amount,
                fee=tx.fee,
                type=tx.type,
                status=tx.status,
                notes=tx.notes,
                created_at=tx.created_at,
            ),
            wallet_number=wallet.wallet_number,
            owner_name=owner.full_name if owner else None,
        )

    # ========== شحن رصيد هاتف (MOBILE TOPUP) ==========

    @classmethod
    def create_mobile_topup(
            cls,
            db: Session,
            user_id: int,
            data: schemas.TopupCreate,
    ) -> models.Transaction:
        # 1) جلب عملة الريال اليمني من النظام
        yer_currency = db.scalar(
            select(wallet_models.Currency).where(
                wallet_models.Currency.symbol == "YER"
            )
        )
        if not yer_currency:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="عملة الريال اليمني غير مهيأة في النظام",
            )

        if not yer_currency.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="عملة الريال اليمني غير مفعلة",
            )

        # 2) جلب حساب المستخدم بالريال اليمني تلقائيًا
        account = db.scalar(
            select(wallet_models.WalletAccount)
            .join(wallet_models.Wallet)
            .where(
                wallet_models.Wallet.user_id == user_id,
                wallet_models.WalletAccount.currency_id == yer_currency.currency_id,
            )
        )
        if not account:
            with db.begin_nested():
                cls._log_failed_tx(
                    db,
                    user_id=user_id,
                    currency_id=yer_currency.currency_id,
                    amount=Decimal(str(data.amount)),
                    tx_type=schemas.TransactionType.MOBILE_TOPUP,
                    reason="لا يوجد حساب ريال يمني للمستخدم",
                    notes=data.notes,
                )
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="لا يوجد حساب ريال يمني للمستخدم",
            )

        if account.status != "ACTIVE":
            with db.begin_nested():
                cls._log_failed_tx(
                    db,
                    user_id=user_id,
                    currency_id=yer_currency.currency_id,
                    amount=Decimal(str(data.amount)),
                    tx_type=schemas.TransactionType.MOBILE_TOPUP,
                    reason="حساب الريال اليمني غير نشط",
                    notes=data.notes,
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="حساب الريال اليمني غير نشط",
            )

        amount = Decimal(str(data.amount))
        fee = cls._get_setting_decimal(db, "mobile_topup_fee", "0.00")
        total_debit = cls._total_debit(amount, fee)

        if Decimal(str(account.balance)) < total_debit:
            with db.begin_nested():
                cls._log_failed_tx(
                    db,
                    user_id=user_id,
                    currency_id=yer_currency.currency_id,
                    amount=amount,
                    tx_type=schemas.TransactionType.MOBILE_TOPUP,
                    reason="الرصيد غير كافٍ لشحن الهاتف",
                    notes=data.notes,
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="الرصيد غير كافٍ لشحن الهاتف",
            )

        try:
            # توليد مرجع داخلي من الـ backend
            ref = cls._generate_ref("TEL")

            # احتياط: نتأكد أنه غير مكرر
            while db.scalar(
                    select(models.TransactionTopup).where(
                        models.TransactionTopup.transaction_ref == ref
                    )
            ):
                ref = cls._generate_ref("TEL")

            # شحن الهاتف = خصم من رصيد العميل
            account.balance = Decimal(str(account.balance)) - total_debit
            db.add(account)
            db.flush()

            cls._credit_fee_to_master_wallet(db, yer_currency.currency_id, fee)

            base = schemas.TransactionBase(
                amount=amount,
                fee=fee,
                currency_id=yer_currency.currency_id,
            )
            tx = cls._create_transaction(
                db=db,
                user_id=user_id,
                payload=base,
                tx_type=schemas.TransactionType.MOBILE_TOPUP,
                status=schemas.TransactionStatus.PENDING,
                notes=data.notes,
            )

            topup = models.TransactionTopup(
                transaction_id=tx.transaction_id,
                phone_number=data.phone_number,
                package_code=data.package_code,
                transaction_ref=ref,
                status_details="PENDING",
            )
            db.add(topup)
            db.flush()

            # مؤقتًا: نفترض نجاح المزود
            tx.status = schemas.TransactionStatus.COMPLETED.value
            topup.status_details = "SUCCESS"

            db.commit()
            db.refresh(tx)
            db.refresh(topup)

            return schemas.TopupOut(
                transaction=schemas.TransactionOut(
                    transaction_id=tx.transaction_id,
                    user_id=tx.user_id,
                    currency_id=tx.currency_id,
                    amount=tx.amount,
                    fee=tx.fee,
                    type=tx.type,
                    status=tx.status,
                    notes=tx.notes,
                    created_at=tx.created_at,
                ),
                topup_id=topup.topup_id,
                phone_number=topup.phone_number,
                package_code=topup.package_code,
                transaction_ref=topup.transaction_ref,
                status_details=topup.status_details,
            )

        except Exception:
            db.rollback()
            raise

    # ========== صرف عملة (EXCHANGE) ==========

    @classmethod
    def create_exchange(
            cls,
            db: Session,
            user_id: int,
            data: schemas.ExchangeCreate,
    ) -> schemas.ExchangeOut:
        if data.from_account_id == data.to_account_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="لا يمكن المصارفة لنفس الحساب",
            )

        from_account = db.scalar(
            select(wallet_models.WalletAccount)
            .join(wallet_models.Wallet)
            .where(
                wallet_models.WalletAccount.account_id == data.from_account_id,
                wallet_models.Wallet.user_id == user_id,
            )
        )
        to_account = db.scalar(
            select(wallet_models.WalletAccount)
            .join(wallet_models.Wallet)
            .where(
                wallet_models.WalletAccount.account_id == data.to_account_id,
                wallet_models.Wallet.user_id == user_id,
            )
        )

        if not from_account or not to_account:
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=0,
                amount=Decimal(str(data.from_amount)),
                tx_type=schemas.TransactionType.EXCHANGE,
                reason="أحد الحسابين غير موجود أو لا يتبع للمستخدم",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="أحد الحسابين غير موجود أو لا يتبع للمستخدم",
            )

        if from_account.status != "ACTIVE":
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=from_account.currency_id,
                amount=Decimal(str(data.from_amount)),
                tx_type=schemas.TransactionType.EXCHANGE,
                reason="حساب المصدر غير نشط",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="حساب المصدر غير نشط",
            )

        if to_account.status != "ACTIVE":
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=from_account.currency_id,
                amount=Decimal(str(data.from_amount)),
                tx_type=schemas.TransactionType.EXCHANGE,
                reason="حساب الوجهة غير نشط",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="حساب الوجهة غير نشط",
            )

        from_currency_id = from_account.currency_id
        to_currency_id = to_account.currency_id

        if from_currency_id == to_currency_id:
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=from_currency_id,
                amount=Decimal(str(data.from_amount)),
                tx_type=schemas.TransactionType.EXCHANGE,
                reason="لا يمكن المصارفة بين حسابين بنفس العملة",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="لا يمكن المصارفة بين حسابين بنفس العملة",
            )

        from_currency = WalletService.get_currency_by_id(db, from_currency_id)
        to_currency = WalletService.get_currency_by_id(db, to_currency_id)

        if not from_currency or not to_currency:
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=from_currency_id,
                amount=Decimal(str(data.from_amount)),
                tx_type=schemas.TransactionType.EXCHANGE,
                reason="العملة غير موجودة",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="العملة غير موجودة",
            )

        applied_rate = ExchangeRateService.get_rate_value(
            db=db,
            base_currency=from_currency.symbol,
            target_currency=to_currency.symbol,
        )
        from_amount = Decimal(str(data.from_amount))
        to_amount = (from_amount * applied_rate).quantize(Decimal("0.01"))

        if Decimal(str(from_account.balance)) < from_amount:
            cls._log_failed_tx(
                db,
                user_id=user_id,
                currency_id=from_currency_id,
                amount=from_amount,
                tx_type=schemas.TransactionType.EXCHANGE,
                reason="الرصيد غير كافٍ",
                notes=data.notes,
            )
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="الرصيد غير كافٍ لإتمام العملية",
            )

        try:
            from_account.balance = Decimal(str(from_account.balance)) - from_amount
            to_account.balance = Decimal(str(to_account.balance)) + to_amount

            base = schemas.TransactionBase(
                amount=from_amount,
                fee=Decimal("0.00"),
                currency_id=from_currency_id,
            )
            tx = cls._create_transaction(
                db=db,
                user_id=user_id,
                payload=base,
                tx_type=schemas.TransactionType.EXCHANGE,
                status=schemas.TransactionStatus.COMPLETED,
                notes=data.notes,
            )

            exch = models.TransactionExchange(
                transaction_id=tx.transaction_id,
                from_currency=from_currency_id,
                to_currency=to_currency_id,
                to_amount=to_amount,
                exchange_rate=applied_rate,
            )
            db.add(exch)

            db.commit()
            db.refresh(tx)
            db.refresh(exch)

            return schemas.ExchangeOut(
                transaction=schemas.TransactionOut(
                    transaction_id=tx.transaction_id,
                    user_id=tx.user_id,
                    currency_id=tx.currency_id,
                    amount=tx.amount,
                    fee=tx.fee,
                    type=tx.type,
                    status=tx.status,
                    notes=tx.notes,
                    created_at=tx.created_at,
                ),
                exchange_id=exch.exchange_id,
                from_currency=exch.from_currency,
                to_currency=exch.to_currency,
                to_amount=exch.to_amount,
                exchange_rate=exch.exchange_rate,
            )

        except Exception:
            db.rollback()
            raise

    # ========== طلب سحب من الصراف (ATM WITHDRAW) ==========

    @classmethod
    def create_atm_withdraw_request(
            cls,
            db: Session,
            user_id: int,
            data: schemas.ATMWithdrawCreate,
    ) -> schemas.ATMWithdrawOut:
        account = db.scalar(
            select(wallet_models.WalletAccount)
            .join(wallet_models.Wallet)
            .where(
                wallet_models.WalletAccount.account_id == data.account_id,
                wallet_models.Wallet.user_id == user_id,
            )
        )
        if not account:
            with db.begin_nested():
                cls._log_failed_tx(
                    db,
                    user_id=user_id,
                    currency_id=None,
                    amount=Decimal(data.amount),
                    tx_type=schemas.TransactionType.ATM_WITHDRAW,
                    reason="الحساب غير موجود أو لا يتبع للمستخدم",
                    notes=data.message,
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="الحساب غير موجود أو لا يتبع للمستخدم",
            )

        amount = Decimal(data.amount)
        if Decimal(account.balance) < amount:
            with db.begin():
                cls._log_failed_tx(
                    db,
                    user_id=user_id,
                    currency_id=account.currency_id,
                    amount=amount,
                    tx_type=schemas.TransactionType.ATM_WITHDRAW,
                    reason="الرصيد غير كافٍ",
                    notes=data.message,
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="الرصيد غير كافٍ لإتمام العملية",
            )

        bank = db.scalar(
            select(banking_models.LinkingBank).where(
                banking_models.LinkingBank.bank_id == data.bank_id
            )
        )
        if not bank:
            with db.begin_nested():
                cls._log_failed_tx(
                    db,
                    user_id=user_id,
                    currency_id=account.currency_id,
                    amount=amount,
                    tx_type=schemas.TransactionType.ATM_WITHDRAW,
                    reason="البنك غير موجود",
                    notes=data.message,
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="البنك غير موجود",
            )

        try:
            # account.balance = Decimal(account.balance) - amount

            base = schemas.TransactionBase(
                amount=amount,
                fee=Decimal("0.00"),
                currency_id=account.currency_id,
            )
            tx = cls._create_transaction(
                db=db,
                user_id=user_id,
                payload=base,
                tx_type=schemas.TransactionType.ATM_WITHDRAW,
                status=schemas.TransactionStatus.PENDING,
                notes=data.message,
            )

            code = cls._generate_ref("ATM")[:11]
            transaction_ref = cls._generate_ref("AR")
            expires = datetime.utcnow() + timedelta(hours=1)

            req = models.ATMWithdrawRequest(
                user_id=user_id,
                bank_id=data.bank_id,
                transaction_id=tx.transaction_id,
                code=code,
                amount=amount,
                currency=account.currency_id,
                pin_code=cls._generate_ref("PIN")[:10],
                message=data.message,
                status="PENDING",
                expires_at=expires,
                transaction_ref=transaction_ref,
                created_at=datetime.utcnow(),
            )
            db.add(req)
            db.commit()
            db.refresh(req)

            return schemas.ATMWithdrawOut(
                request_id=req.request_id,
                user_id=req.user_id,
                bank_id=req.bank_id,
                bank_name=bank.name,
                bank_code=bank.code,
                transaction_id=req.transaction_id,
                code=req.code,
                pin_code=req.pin_code,
                amount=req.amount,
                currency=req.currency,
                status=req.status,
                expires_at=req.expires_at,
                transaction_ref=req.transaction_ref,
                created_at=req.created_at,
            )
        except Exception:
            db.rollback()
            raise

    # اضافات جديدة

    @classmethod
    def create_cash_deposit(
            cls,
            db: Session,
            staff_id: int,
            data: schemas.CashDepositCreate,
    ):
        wallet = db.scalar(
            select(wallet_models.Wallet).where(
                wallet_models.Wallet.wallet_number == data.wallet_number
            )
        )
        if not wallet:
            raise HTTPException(status_code=400, detail="رقم المحفظة غير موجود")

        account = db.scalar(
            select(wallet_models.WalletAccount).where(
                wallet_models.WalletAccount.wallet_id == wallet.wallet_id,
                wallet_models.WalletAccount.currency_id == data.currency_id,
            )
        )
        if not account:
            raise HTTPException(
                status_code=400,
                detail="لا يوجد حساب بهذه العملة داخل المحفظة"
            )

        amount = Decimal(str(data.amount))
        if amount <= 0:
            raise HTTPException(status_code=400, detail="المبلغ يجب أن يكون أكبر من صفر")

        account.balance = Decimal(str(account.balance)) + amount
        db.add(account)
        db.flush()

        base = schemas.TransactionBase(
            amount=amount,
            fee=Decimal("0.00"),
            currency_id=data.currency_id,
        )

        tx = cls._create_transaction(
            db=db,
            user_id=wallet.user_id,
            payload=base,
            tx_type=schemas.TransactionType.CASH_DEPOSIT,
            status=schemas.TransactionStatus.COMPLETED,
            notes=data.notes,
        )
        db.flush()

        reference_number = f"{random.randint(1_000_000_000, 9_999_999_999)}"

        cash_deposit_details = models.TransactionCashDeposit(
            transaction_id=tx.transaction_id,
            staff_id=staff_id,
            wallet_id=wallet.wallet_id,
            depositor_name=data.depositor_name,
            depositor_phone=data.depositor_phone,
            reference_number=reference_number,
        )
        db.add(cash_deposit_details)
        db.flush()

        owner = db.scalar(
            select(auth_models.User).where(auth_models.User.user_id == wallet.user_id)
        )

        db.commit()
        db.refresh(tx)

        return schemas.CashDepositOut(
            transaction=schemas.TransactionOut(
                transaction_id=tx.transaction_id,
                user_id=tx.user_id,
                currency_id=tx.currency_id,
                amount=tx.amount,
                fee=tx.fee,
                type=tx.type,
                status=tx.status,
                notes=tx.notes,
                created_at=tx.created_at,
            ),
            wallet_number=wallet.wallet_number,
            owner_name=owner.full_name if owner else None,
            depositor_name=data.depositor_name,
            depositor_phone=data.depositor_phone,
            reference_number=reference_number,
        )
