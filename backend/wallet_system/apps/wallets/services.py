# apps/wallets/services.py

from datetime import datetime, date
import random
import string
from typing import Optional, List
from decimal import Decimal
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import select
from . import models
from . import schemas
from ..core.security import get_password_hash
from ..auth import models as model


class WalletService:

    # -------- Wallet Helpers --------

    @staticmethod
    def _generate_wallet_number() -> str:
        """
        توليد رقم محفظة فريد بشكل بسيط:
        W + 14 رقم عشوائي
        """
        digits = "".join(random.choices(string.digits, k=10))
        return digits

    @classmethod
    def _create_unique_wallet_number(cls, db: Session) -> str:
        """
        يحاول توليد wallet_number غير مستخدم
        """
        while True:
            number = cls._generate_wallet_number()
            exists = db.scalar(
                select(models.Wallet).where(models.Wallet.wallet_number == number)
            )
            if not exists:
                return number

    # -------- Wallet CRUD --------

    @classmethod
    def get_wallet_by_user_id(cls, db: Session, user_id: int) -> Optional[models.Wallet]:
        return db.scalar(
            select(models.Wallet)
            .where(models.Wallet.user_id == user_id)
            .options(
                joinedload(models.Wallet.accounts).joinedload(models.WalletAccount.currency)
            )
        )

    @classmethod
    def get_or_create_wallet_for_user(cls, db: Session, user_id: int) -> models.Wallet:
        wallet = cls.get_wallet_by_user_id(db, user_id)
        if wallet:
            return wallet

        wallet_number = cls._create_unique_wallet_number(db)
        wallet = models.Wallet(
            user_id=user_id,
            wallet_number=wallet_number,
            is_system=False,
            status="ACTIVE",
            created_at=datetime.utcnow(),
        )
        db.add(wallet)
        db.flush()
        # db.commit()
        # db.refresh(wallet)
        return wallet

    @classmethod
    def change_wallet_status(
            cls,
            db: Session,
            wallet: models.Wallet,
            status: schemas.WalletStatus,
    ) -> models.Wallet:
        wallet.status = status.value
        if status == schemas.WalletStatus.CLOSED:
            wallet.closed_at = datetime.utcnow()
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
        return wallet

    # -------- Currency Helpers --------

    @staticmethod
    def get_currency_by_id(db: Session, currency_id: int) -> Optional[models.Currency]:
        return db.get(models.Currency, currency_id)

    @staticmethod
    def list_active_currencies(db: Session) -> List[models.Currency]:
        return list(
            db.scalars(
                select(models.Currency).where(models.Currency.is_active == True)  # noqa: E712
            )
        )

    # -------- WalletAccount CRUD --------

    @staticmethod
    def list_wallet_accounts(db: Session, wallet_id: int) -> List[models.WalletAccount]:
        return list(
            db.scalars(
                select(models.WalletAccount)
                .where(models.WalletAccount.wallet_id == wallet_id)
                .options(joinedload(models.WalletAccount.currency))
                .order_by(models.WalletAccount.currency_id.asc())
            )
        )

    @staticmethod
    def get_wallet_account_by_id(
            db: Session, account_id: int
    ) -> Optional[models.WalletAccount]:
        return db.scalar(
            select(models.WalletAccount)
            .where(models.WalletAccount.account_id == account_id)
            .options(joinedload(models.WalletAccount.currency))
        )

    @staticmethod
    def get_wallet_account_for_user(
            db: Session, account_id: int, user_id: int
    ) -> Optional[models.WalletAccount]:
        return db.scalar(
            select(models.WalletAccount)
            .join(models.Wallet)
            .where(
                models.WalletAccount.account_id == account_id,
                models.Wallet.user_id == user_id,
            )
            .options(joinedload(models.WalletAccount.currency))
        )

    @classmethod
    def create_wallet_account(
            cls,
            db: Session,
            wallet: models.Wallet,
            currency: models.Currency,
            initial_balance: float = 0.0,
    ) -> models.WalletAccount:
        # هل يوجد حساب لنفس العملة مسبقًا؟
        existing = db.scalar(
            select(models.WalletAccount).where(
                models.WalletAccount.wallet_id == wallet.wallet_id,
                models.WalletAccount.currency_id == currency.currency_id,
            )
        )
        if existing:
            return existing

        account = models.WalletAccount(
            wallet_id=wallet.wallet_id,
            currency_id=currency.currency_id,
            balance=initial_balance,
            status="ACTIVE",
        )
        db.add(account)
        db.flush()
        # db.commit()
        # db.refresh(account)
        return account

    @classmethod
    def ensure_default_accounts(
            cls,
            db: Session,
            wallet: models.Wallet,
            currency_ids: list[int],
    ) -> list[models.WalletAccount]:
        """
        تنشئ حسابات للمحفظة لعملات محددة (مثلاً 3 عملات)
        """
        accounts: list[models.WalletAccount] = []

        currencies = list(
            db.scalars(
                select(models.Currency)
                .where(models.Currency.currency_id.in_(currency_ids))
                .order_by(models.Currency.currency_id.asc())
            )
        )

        # لو عملة ID خطأ أو غير موجودة
        if len(currencies) != len(currency_ids):
            found_ids = {c.currency_id for c in currencies}
            missing = [cid for cid in currency_ids if cid not in found_ids]
            raise ValueError(f"Missing currencies: {missing}")

        for currency in currencies:
            acc = cls.create_wallet_account(db, wallet, currency, initial_balance=0.0)
            accounts.append(acc)

        return accounts

    @classmethod
    def change_wallet_account_status(
            cls,
            db: Session,
            account: models.WalletAccount,
            status: schemas.WalletAccountStatus,
    ) -> models.WalletAccount:
        account.status = status.value
        db.add(account)
        db.commit()
        db.refresh(account)
        return account

    # اضافات جديدة

    @classmethod
    def create_system_user(cls, db: Session) -> model.User:
        existing = db.scalar(
            select(model.User).where(model.User.user_type == "SYSTEM")
        )
        if existing:
            return existing

        user = model.User(
            phone_number="000000000",
            email=None,
            password_hash=get_password_hash("UNUSED_RANDOM_SECRET_123"),
            full_name="SYSTEM MASTER",
            date_of_birth=date(2000, 1, 1),
            is_verified=True,
            daily_limit=Decimal("99999999.99"),
            monthly_limit=Decimal("99999999.99"),
            user_type="SYSTEM",
            gender="MALE",
            is_active=True,
        )
        db.add(user)
        db.flush()
        return user

    @classmethod
    def get_master_wallet(cls, db: Session) -> Optional[models.Wallet]:
        return db.scalar(
            select(models.Wallet).where(models.Wallet.is_system == True)  # noqa: E712
        )

    @classmethod
    def create_master_wallet(cls, db: Session, system_user_id: int) -> models.Wallet:
        existing = cls.get_master_wallet(db)
        if existing:
            return existing

        wallet_number = cls._create_unique_wallet_number(db)
        wallet = models.Wallet(
            user_id=system_user_id,
            wallet_number=wallet_number,
            is_system=True,
            status="ACTIVE",
            created_at=datetime.utcnow(),
        )
        db.add(wallet)
        db.flush()
        return wallet

    @classmethod
    def get_master_wallet_account(
            cls,
            db: Session,
            currency_id: int,
    ) -> Optional[models.WalletAccount]:
        master_wallet = cls.get_master_wallet(db)
        if not master_wallet:
            return None

        return db.scalar(
            select(models.WalletAccount).where(
                models.WalletAccount.wallet_id == master_wallet.wallet_id,
                models.WalletAccount.currency_id == currency_id,
            )
        )

    @classmethod
    def initial_funding(
            cls,
            db: Session,
            currency_id: int,
            amount: Decimal,
    ) -> models.WalletAccount:
        master_wallet = cls.get_master_wallet(db)
        if not master_wallet:
            raise ValueError("Master wallet does not exist")

        account = db.scalar(
            select(models.WalletAccount).where(
                models.WalletAccount.wallet_id == master_wallet.wallet_id,
                models.WalletAccount.currency_id == currency_id,
            )
        )
        if not account:
            raise ValueError("Master wallet account for this currency does not exist")

        amount = Decimal(str(amount))
        if amount <= 0:
            raise ValueError("Amount must be greater than zero")

        account.balance = Decimal(str(account.balance)) + Decimal(str(amount))
        db.add(account)
        db.flush()
        return account
