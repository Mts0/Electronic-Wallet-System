from __future__ import annotations

import re
from decimal import Decimal, InvalidOperation
from typing import Any, Iterable

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from apps.auth import models as auth_models
from apps.wallets.services import WalletService
from apps.transactions.services import TransactionService
from apps.ExchangeRates.services import ExchangeRateService
from apps.Favorites.services import FavoritesService
from apps.Banking.services import BankingService
from apps.transactions import schemas as transaction_schemas
from apps.Favorites import schemas as favorite_schemas

from . import schemas


class WalletAIAgentService:
    CURRENCY_ALIASES = {
        "yer": "YER",
        "ريال": "YER",
        "الريال": "YER",
        "ريال يمني": "YER",
        "يمني": "YER",
        "usd": "USD",
        "دولار": "USD",
        "الدولار": "USD",
        "دولار امريكي": "USD",
        "دولار أمريكي": "USD",
        "sar": "SAR",
        "ريال سعودي": "SAR",
        "سعودي": "SAR",
        "الريال السعودي": "SAR",
        "eur": "EUR",
        "يورو": "EUR",
        "euro": "EUR",
        "aed": "AED",
        "درهم": "AED",
        "درهم اماراتي": "AED",
        "درهم إماراتي": "AED",
    }

    CAPABILITIES = [
        schemas.AgentCapability(
            intent=schemas.AgentIntent.GET_WALLET_SUMMARY,
            description="إرجاع بيانات المحفظة وحساباتها وأرصدتها",
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.LIST_TRANSACTIONS,
            description="عرض آخر العمليات الخاصة بالمستخدم مع دعم التصفية",
            optional_fields=["limit", "status_filter", "type_filter"],
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.LIST_FAILED_TRANSACTIONS,
            description="عرض العمليات الفاشلة فقط",
            optional_fields=["limit"],
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.TRANSFER_MONEY,
            description="تنفيذ تحويل مالي من حساب المستخدم إلى رقم محفظة آخر مع إمكانية تحديد الحساب تلقائياً بالعملة",
            required_fields=["to_wallet_number", "amount"],
            optional_fields=["from_account_id", "from_currency", "notes"],
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.MOBILE_TOPUP,
            description="شحن رصيد هاتف من المحفظة",
            required_fields=["amount", "phone_number"],
            optional_fields=["package_code", "notes"],
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.EXCHANGE_MONEY,
            description="تحويل مبلغ من عملة إلى عملة داخل حسابات محفظة المستخدم مع تحديد الحسابات تلقائياً إن أمكن",
            required_fields=["from_amount"],
            optional_fields=["from_account_id", "to_account_id", "from_currency", "to_currency", "notes"],
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.ATM_WITHDRAW_REQUEST,
            description="إنشاء طلب سحب من الصراف مع إمكانية تحديد الحساب والبنك تلقائياً",
            required_fields=["amount", "bank"],
            optional_fields=["account_id", "currency", "message"],
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.GET_EXCHANGE_RATE,
            description="جلب سعر الصرف بين عملتين",
            required_fields=["base_currency", "target_currency"],
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.LIST_CURRENCIES,
            description="عرض العملات الفعالة داخل النظام",
        ),
        schemas.AgentCapability(
            intent=schemas.AgentIntent.ADD_FAVORITE_CONTACT,
            description="إضافة جهة اتصال مفضلة",
            required_fields=["name", "phone_number"],
        ),
    ]

    @classmethod
    def list_capabilities(cls) -> list[schemas.AgentCapability]:
        return cls.CAPABILITIES

    @classmethod
    def analyze_request(
        cls,
        db: Session,
        current_user: auth_models.User,
        request: schemas.AgentExecuteRequest,
    ) -> schemas.AgentPlan:
        text = (request.message or "").strip()
        params = dict(request.params or {})

        intent = request.intent or cls._infer_intent(text)
        normalized = cls._extract_params(db, current_user, intent, text, params)
        missing = cls._missing_fields(intent, normalized)
        user_message = cls._build_user_message(intent, missing, request.dry_run)
        confidence = cls._confidence(intent, missing, request.intent is not None)

        return schemas.AgentPlan(
            intent=intent,
            confidence=confidence,
            normalized_params=normalized,
            missing_fields=missing,
            user_message=user_message,
        )

    @classmethod
    def execute(
        cls,
        db: Session,
        current_user: auth_models.User,
        request: schemas.AgentExecuteRequest,
    ) -> schemas.AgentExecuteResponse:
        plan = cls.analyze_request(db=db, current_user=current_user, request=request)

        if request.dry_run or plan.intent == schemas.AgentIntent.UNKNOWN or plan.missing_fields:
            return schemas.AgentExecuteResponse(
                ok=plan.intent != schemas.AgentIntent.UNKNOWN,
                executed=False,
                plan=plan,
                result=None,
            )

        result = cls._dispatch(db=db, current_user=current_user, intent=plan.intent, params=plan.normalized_params)
        return schemas.AgentExecuteResponse(ok=True, executed=True, plan=plan, result=result)

    @classmethod
    def _dispatch(cls, db: Session, current_user: auth_models.User, intent: schemas.AgentIntent, params: dict[str, Any]) -> dict[str, Any]:
        if intent == schemas.AgentIntent.GET_WALLET_SUMMARY:
            wallet = WalletService.get_wallet_by_user_id(db, current_user.user_id)
            if not wallet:
                raise HTTPException(status_code=404, detail="لا توجد محفظة مرتبطة بهذا المستخدم")
            return {
                "wallet_id": wallet.wallet_id,
                "wallet_number": wallet.wallet_number,
                "status": wallet.status,
                "accounts": [
                    {
                        "account_id": acc.account_id,
                        "currency_id": acc.currency_id,
                        "currency_name": getattr(acc.currency, "name", None),
                        "currency_symbol": getattr(acc.currency, "symbol", None),
                        "balance": str(acc.balance),
                        "status": acc.status,
                    }
                    for acc in wallet.accounts
                ],
            }

        if intent == schemas.AgentIntent.LIST_TRANSACTIONS:
            txs = TransactionService.list_user_transactions(
                db=db,
                user_id=current_user.user_id,
                limit=int(params.get("limit", 10)),
                status_filter=params.get("status_filter"),
                type_filter=params.get("type_filter"),
            )
            return cls._serialize_transactions(txs, summary_message="تم جلب العمليات")

        if intent == schemas.AgentIntent.LIST_FAILED_TRANSACTIONS:
            txs = TransactionService.list_user_transactions(
                db=db,
                user_id=current_user.user_id,
                limit=int(params.get("limit", 10)),
                status_filter=transaction_schemas.TransactionStatus.FAILED,
            )
            return cls._serialize_transactions(txs, summary_message="تم جلب العمليات الفاشلة")

        cls._ensure_kyc(current_user)

        if intent == schemas.AgentIntent.TRANSFER_MONEY:
            payload_data = dict(params)
            payload_data.pop("from_currency", None)
            payload = transaction_schemas.TransferCreate(**payload_data)
            tx = TransactionService.create_transfer(db=db, user_id=current_user.user_id, data=payload)
            return {
                "message": "تم تنفيذ التحويل بنجاح",
                "transaction_id": tx.transaction.transaction_id,
                "transfers_id": tx.transfers_id,
                "to_wallet_number": tx.to_wallet_number,
                "to_user_name": tx.to_user_name,
                "amount": str(tx.transaction.amount),
                "fee": str(tx.transaction.fee),
                "status": tx.transaction.status,
            }

        if intent == schemas.AgentIntent.MOBILE_TOPUP:
            payload = transaction_schemas.TopupCreate(**params)
            tx = TransactionService.create_mobile_topup(db=db, user_id=current_user.user_id, data=payload)
            return {
                "message": "تم تنفيذ شحن الرصيد بنجاح",
                "transaction_id": tx.transaction.transaction_id,
                "topup_id": tx.topup_id,
                "phone_number": tx.phone_number,
                "amount": str(tx.transaction.amount),
                "fee": str(tx.transaction.fee),
                "status": tx.transaction.status,
                "transaction_ref": tx.transaction_ref,
            }

        if intent == schemas.AgentIntent.EXCHANGE_MONEY:
            payload_data = dict(params)
            payload_data.pop("from_currency", None)
            payload_data.pop("to_currency", None)
            payload = transaction_schemas.ExchangeCreate(**payload_data)
            tx = TransactionService.create_exchange(db=db, user_id=current_user.user_id, data=payload)
            return {
                "message": "تم تنفيذ الصرف بنجاح",
                "transaction_id": tx.transaction.transaction_id,
                "exchange_id": tx.exchange_id,
                "from_currency": tx.from_currency,
                "to_currency": tx.to_currency,
                "from_amount": str(tx.transaction.amount),
                "to_amount": str(tx.to_amount),
                "exchange_rate": str(tx.exchange_rate),
                "status": tx.transaction.status,
            }

        if intent == schemas.AgentIntent.ATM_WITHDRAW_REQUEST:
            payload_data = dict(params)
            payload_data.pop("bank", None)
            payload_data.pop("currency", None)
            payload = transaction_schemas.ATMWithdrawCreate(**payload_data)
            req = TransactionService.create_atm_withdraw_request(db=db, user_id=current_user.user_id, data=payload)
            return {
                "message": "تم إنشاء طلب السحب من الصراف بنجاح",
                "request_id": req.request_id,
                "transaction_id": req.transaction_id,
                "bank_id": req.bank_id,
                "bank_name": req.bank_name,
                "amount": str(req.amount),
                "currency": req.currency,
                "code": req.code,
                "pin_code": req.pin_code,
                "status": req.status,
                "expires_at": req.expires_at.isoformat() if req.expires_at else None,
            }

        if intent == schemas.AgentIntent.GET_EXCHANGE_RATE:
            rate = ExchangeRateService.get_rate_by_pair(db, params["base_currency"], params["target_currency"])
            if not rate:
                raise HTTPException(status_code=404, detail="سعر الصرف غير موجود لهذا الزوج")
            return {
                "rate_id": rate.rate_id,
                "base_currency": rate.base_currency,
                "target_currency": rate.target_currency,
                "rate": str(rate.rate_value),
                "updated_at": rate.updated_at.isoformat() if getattr(rate, "updated_at", None) else None,
            }

        if intent == schemas.AgentIntent.LIST_CURRENCIES:
            currencies = WalletService.list_active_currencies(db)
            return {
                "count": len(currencies),
                "currencies": [
                    {
                        "currency_id": c.currency_id,
                        "name": c.name,
                        "symbol": c.symbol,
                        "is_active": c.is_active,
                    }
                    for c in currencies
                ],
            }

        if intent == schemas.AgentIntent.ADD_FAVORITE_CONTACT:
            payload = favorite_schemas.FavoriteContactCreate(**params)
            fav = FavoritesService.create_contact_for_user(db, current_user.user_id, payload)
            return {
                "message": "تمت إضافة جهة الاتصال إلى المفضلة",
                "fc_id": fav.fc_id,
                "name": fav.name,
                "phone_number": fav.phone_number,
                "created_at": fav.created_at.isoformat() if fav.created_at else None,
            }

        raise HTTPException(status_code=400, detail="العملية غير مدعومة حالياً")

    @classmethod
    def _serialize_transactions(txs: list[Any], summary_message: str) -> dict[str, Any]:
        items = [
            {
                "transaction_id": tx.transaction_id,
                "type": tx.type,
                "status": tx.status,
                "currency_id": tx.currency_id,
                "amount": str(tx.amount),
                "fee": str(tx.fee),
                "notes": tx.notes,
                "created_at": tx.created_at.isoformat() if tx.created_at else None,
            }
            for tx in txs
        ]
        return {
            "message": summary_message,
            "count": len(items),
            "summary": cls._summary_transactions(items),
            "transactions": items,
        }

    @classmethod
    def _ensure_kyc(cls, current_user: auth_models.User) -> None:
        if not current_user.is_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="لا يمكن تنفيذ العمليات المالية قبل إكمال KYC",
            )

    @classmethod
    def _infer_intent(cls, text: str) -> schemas.AgentIntent:
        t = cls._normalize_text(text)

        if any(k in t for k in ["العمليات الفاشلة", "فاشلة فقط", "failed transactions", "failed history"]):
            return schemas.AgentIntent.LIST_FAILED_TRANSACTIONS
        if any(k in t for k in ["سحب من الصراف", "اسحب من الصراف", "atm", "withdraw", "سحب صراف"]):
            return schemas.AgentIntent.ATM_WITHDRAW_REQUEST
        if any(k in t for k in ["الرصيد", "رصيدي", "ملخص المحفظة", "بيانات المحفظة", "حساباتي", "wallet summary", "my wallet"]):
            return schemas.AgentIntent.GET_WALLET_SUMMARY
        if any(k in t for k in ["عملياتي", "معاملاتي", "اخر العمليات", "آخر العمليات", "transactions", "history"]):
            return schemas.AgentIntent.LIST_TRANSACTIONS
        if any(k in t for k in ["حول", "تحويل", "ارسل", "أرسل", "transfer"]):
            return schemas.AgentIntent.TRANSFER_MONEY
        if any(k in t for k in ["اشحن", "شحن", "topup", "mobile topup", "رصيد هاتف"]):
            return schemas.AgentIntent.MOBILE_TOPUP
        if any(k in t for k in ["صرف", "تحويل عملة", "exchange"]):
            return schemas.AgentIntent.EXCHANGE_MONEY
        if any(k in t for k in ["سعر الصرف", "كم سعر", "exchange rate", "rate"]):
            return schemas.AgentIntent.GET_EXCHANGE_RATE
        if any(k in t for k in ["العملات", "currencies", "currency list"]):
            return schemas.AgentIntent.LIST_CURRENCIES
        if any(k in t for k in ["مفضلة", "مفضلتي", "جهة اتصال", "favorite contact", "اضف جهة"]):
            return schemas.AgentIntent.ADD_FAVORITE_CONTACT
        return schemas.AgentIntent.UNKNOWN

    @classmethod
    def _extract_params(cls, db: Session, current_user: auth_models.User, intent: schemas.AgentIntent, text: str, existing: dict[str, Any]) -> dict[str, Any]:
        params = dict(existing)
        t = cls._normalize_text(text)

        if intent == schemas.AgentIntent.LIST_TRANSACTIONS:
            params.setdefault("limit", cls._extract_int(t, [r"(?:اخر|آخر|latest)\s*(\d+)", r"limit\s*(\d+)"]) or 10)
            cls._apply_transaction_filters(t, params)
            return cls._clean(params)

        if intent == schemas.AgentIntent.LIST_FAILED_TRANSACTIONS:
            params.setdefault("limit", cls._extract_int(t, [r"(?:اخر|آخر|latest)\s*(\d+)", r"limit\s*(\d+)"]) or 10)
            return cls._clean(params)

        if intent == schemas.AgentIntent.TRANSFER_MONEY:
            params.setdefault("amount", cls._extract_decimal(t))
            params.setdefault("from_account_id", cls._extract_int(t, [r"from[_\s-]?account(?:_id)?\s*(\d+)", r"من الحساب\s*(\d+)"]))
            params.setdefault("from_currency", cls._extract_currency(t))
            params.setdefault("to_wallet_number", cls._extract_wallet_number(text))
            params.setdefault("notes", cls._extract_notes(text))
            if not params.get("from_account_id") and params.get("from_currency"):
                account = cls._find_user_account_by_currency(db, current_user.user_id, params["from_currency"])
                if account:
                    params["from_account_id"] = account.account_id
            if not params.get("from_account_id"):
                account = cls._pick_default_account(db, current_user.user_id)
                if account:
                    params["from_account_id"] = account.account_id
            return cls._clean(params)

        if intent == schemas.AgentIntent.MOBILE_TOPUP:
            params.setdefault("amount", cls._extract_decimal(t))
            params.setdefault("phone_number", cls._extract_phone(text))
            params.setdefault("notes", cls._extract_notes(text))
            return cls._clean(params)

        if intent == schemas.AgentIntent.EXCHANGE_MONEY:
            params.setdefault("from_amount", cls._extract_decimal(t))
            params.setdefault("from_account_id", cls._extract_int(t, [r"من الحساب\s*(\d+)", r"from[_\s-]?account(?:_id)?\s*(\d+)"]))
            params.setdefault("to_account_id", cls._extract_int(t, [r"(?:الى|إلى) الحساب\s*(\d+)", r"to[_\s-]?account(?:_id)?\s*(\d+)"]))
            from_currency, to_currency = cls._extract_currency_pair(text)
            params.setdefault("from_currency", params.get("from_currency") or from_currency)
            params.setdefault("to_currency", params.get("to_currency") or to_currency)
            params.setdefault("notes", cls._extract_notes(text))
            if not params.get("from_account_id") and params.get("from_currency"):
                account = cls._find_user_account_by_currency(db, current_user.user_id, params["from_currency"])
                if account:
                    params["from_account_id"] = account.account_id
            if not params.get("to_account_id") and params.get("to_currency"):
                account = cls._find_user_account_by_currency(db, current_user.user_id, params["to_currency"])
                if account:
                    params["to_account_id"] = account.account_id
            return cls._clean(params)

        if intent == schemas.AgentIntent.ATM_WITHDRAW_REQUEST:
            params.setdefault("amount", cls._extract_decimal(t))
            params.setdefault("account_id", cls._extract_int(t, [r"من الحساب\s*(\d+)", r"account(?:_id)?\s*(\d+)"]))
            params.setdefault("currency", cls._extract_currency(t))
            params.setdefault("bank", cls._extract_bank_hint(text))
            params.setdefault("message", cls._extract_notes(text))
            if not params.get("account_id") and params.get("currency"):
                account = cls._find_user_account_by_currency(db, current_user.user_id, params["currency"])
                if account:
                    params["account_id"] = account.account_id
            if not params.get("account_id"):
                account = cls._pick_default_account(db, current_user.user_id)
                if account:
                    params["account_id"] = account.account_id
            if params.get("bank") and not params.get("bank_id"):
                bank = cls._resolve_bank(db, params["bank"])
                if bank:
                    params["bank_id"] = bank.bank_id
            return cls._clean(params)

        if intent == schemas.AgentIntent.GET_EXCHANGE_RATE:
            params.setdefault("base_currency", None)
            params.setdefault("target_currency", None)
            base, target = cls._extract_currency_pair(text)
            if base and not params.get("base_currency"):
                params["base_currency"] = base
            if target and not params.get("target_currency"):
                params["target_currency"] = target
            if not params.get("base_currency") or not params.get("target_currency"):
                code_matches = re.findall(r"\b([A-Za-z]{3})\b", text)
                if len(code_matches) >= 2:
                    params.setdefault("base_currency", code_matches[0].upper())
                    params.setdefault("target_currency", code_matches[1].upper())
            return cls._clean(params)

        if intent == schemas.AgentIntent.ADD_FAVORITE_CONTACT:
            params.setdefault("phone_number", cls._extract_phone(text))
            params.setdefault("name", cls._extract_contact_name(text))
            return cls._clean(params)

        return cls._clean(params)

    @classmethod
    def _missing_fields(cls, intent: schemas.AgentIntent, params: dict[str, Any]) -> list[str]:
        required_by_intent = {
            schemas.AgentIntent.TRANSFER_MONEY: ["from_account_id", "to_wallet_number", "amount"],
            schemas.AgentIntent.MOBILE_TOPUP: ["amount", "phone_number"],
            schemas.AgentIntent.EXCHANGE_MONEY: ["from_account_id", "to_account_id", "from_amount"],
            schemas.AgentIntent.ATM_WITHDRAW_REQUEST: ["account_id", "amount", "bank_id"],
            schemas.AgentIntent.GET_EXCHANGE_RATE: ["base_currency", "target_currency"],
            schemas.AgentIntent.ADD_FAVORITE_CONTACT: ["name", "phone_number"],
        }
        required = required_by_intent.get(intent, [])
        return [field for field in required if params.get(field) in (None, "", [])]

    @staticmethod
    def _build_user_message(intent: schemas.AgentIntent, missing_fields: list[str], dry_run: bool) -> str:
        if intent == schemas.AgentIntent.UNKNOWN:
            return "لم أتمكن من تحديد العملية المطلوبة من النص الحالي."
        if missing_fields:
            fields = ", ".join(missing_fields)
            return f"تم التعرف على العملية {intent.value} لكن ما زالت هذه الحقول مطلوبة: {fields}."
        if dry_run:
            return f"تم تحليل الطلب بنجاح ويمكن تنفيذ العملية {intent.value}."
        return f"تم تجهيز العملية {intent.value} للتنفيذ."

    @staticmethod
    def _confidence(intent: schemas.AgentIntent, missing_fields: list[str], explicit: bool) -> float:
        if intent == schemas.AgentIntent.UNKNOWN:
            return 0.15
        score = 0.95 if explicit else 0.82
        if missing_fields:
            score -= min(0.35, 0.1 * len(missing_fields))
        return max(0.2, min(0.99, score))

    @staticmethod
    def _normalize_text(text: str) -> str:
        return re.sub(r"\s+", " ", (text or "").strip().lower())

    @staticmethod
    def _extract_decimal(text: str) -> Decimal | None:
        m = re.search(r"(\d+(?:\.\d{1,2})?)", text)
        if not m:
            return None
        try:
            return Decimal(m.group(1))
        except InvalidOperation:
            return None

    @staticmethod
    def _extract_int(text: str, patterns: list[str]) -> int | None:
        for pattern in patterns:
            m = re.search(pattern, text, re.IGNORECASE)
            if m:
                try:
                    return int(m.group(1))
                except ValueError:
                    return None
        return None

    @staticmethod
    def _extract_phone(text: str) -> str | None:
        m = re.search(r"\b(7\d{8,14}|0\d{8,14}|\+?\d{9,15})\b", text)
        return m.group(1) if m else None

    @classmethod
    def _extract_wallet_number(cls, text: str) -> str | None:
        patterns = [
            r"رقم المحفظة\s*[:\-]?\s*([A-Za-z0-9_-]{6,100})",
            r"(?:الى|إلى|لـ|للمحفظة|to)\s*([A-Za-z0-9_-]{6,100})",
            r"wallet\s*[:\-]?\s*([A-Za-z0-9_-]{6,100})",
        ]
        for pattern in patterns:
            m = re.search(pattern, text, re.IGNORECASE)
            if m:
                return m.group(1).strip()
        return None

    @classmethod
    def _extract_currency(cls, text: str) -> str | None:
        normalized = cls._normalize_text(text)
        for alias, code in sorted(cls.CURRENCY_ALIASES.items(), key=lambda item: len(item[0]), reverse=True):
            if alias in normalized:
                return code
        m = re.search(r"\b([A-Za-z]{3})\b", text)
        return m.group(1).upper() if m else None

    @classmethod
    def _extract_currency_pair(cls, text: str) -> tuple[str | None, str | None]:
        normalized = cls._normalize_text(text)
        explicit_codes = [match.upper() for match in re.findall(r"\b([A-Za-z]{3})\b", text)]
        if len(explicit_codes) >= 2:
            return explicit_codes[0], explicit_codes[1]

        found: list[str] = []
        for alias, code in sorted(cls.CURRENCY_ALIASES.items(), key=lambda item: len(item[0]), reverse=True):
            if alias in normalized and code not in found:
                found.append(code)
        if len(found) >= 2:
            return found[0], found[1]
        return (found[0], None) if found else (None, None)

    @staticmethod
    def _extract_notes(text: str) -> str | None:
        m = re.search(r"(?:ملاحظة|ملاحظات|note|notes|رسالة)\s*[:\-]?\s*(.+)$", text, re.IGNORECASE)
        if m:
            return m.group(1).strip()
        return None

    @staticmethod
    def _extract_contact_name(text: str) -> str | None:
        m = re.search(r"(?:اسمها|اسمه|اسم|name)\s*[:\-]?\s*([\w\u0600-\u06FF ]{2,60})", text, re.IGNORECASE)
        if m:
            return m.group(1).strip()
        return None

    @classmethod
    def _extract_bank_hint(cls, text: str) -> str | int | None:
        m = re.search(r"bank[_\s-]?id\s*[:\-]?\s*(\d+)", text, re.IGNORECASE)
        if m:
            return int(m.group(1))
        m = re.search(r"(?:بنك|bank)\s*[:\-]?\s*([\w\u0600-\u06FF\- ]{2,60})", text, re.IGNORECASE)
        if m:
            return m.group(1).strip()
        return None

    @classmethod
    def _apply_transaction_filters(cls, text: str, params: dict[str, Any]) -> None:
        status_map = {
            "failed": transaction_schemas.TransactionStatus.FAILED,
            "فاشلة": transaction_schemas.TransactionStatus.FAILED,
            "ناجحة": transaction_schemas.TransactionStatus.COMPLETED,
            "completed": transaction_schemas.TransactionStatus.COMPLETED,
            "pending": transaction_schemas.TransactionStatus.PENDING,
            "معلقة": transaction_schemas.TransactionStatus.PENDING,
        }
        type_map = {
            "تحويل": transaction_schemas.TransactionType.TRANSFER,
            "transfer": transaction_schemas.TransactionType.TRANSFER,
            "شحن": transaction_schemas.TransactionType.MOBILE_TOPUP,
            "topup": transaction_schemas.TransactionType.MOBILE_TOPUP,
            "صراف": transaction_schemas.TransactionType.ATM_WITHDRAW,
            "atm": transaction_schemas.TransactionType.ATM_WITHDRAW,
            "صرف": transaction_schemas.TransactionType.EXCHANGE,
            "exchange": transaction_schemas.TransactionType.EXCHANGE,
            "ايداع": transaction_schemas.TransactionType.CASH_DEPOSIT,
            "إيداع": transaction_schemas.TransactionType.CASH_DEPOSIT,
        }
        for key, value in status_map.items():
            if key in text and "status_filter" not in params:
                params["status_filter"] = value
                break
        for key, value in type_map.items():
            if key in text and "type_filter" not in params:
                params["type_filter"] = value
                break

    @classmethod
    def _find_user_account_by_currency(cls, db: Session, user_id: int, currency_hint: str):
        wallet = WalletService.get_wallet_by_user_id(db, user_id)
        if not wallet:
            return None
        target = cls._canonical_currency(currency_hint)
        for account in wallet.accounts:
            symbol = (getattr(account.currency, "symbol", "") or "").upper()
            name = (getattr(account.currency, "name", "") or "").strip().lower()
            if target == symbol or target.lower() == name:
                return account
        return None

    @classmethod
    def _pick_default_account(cls, db: Session, user_id: int):
        wallet = WalletService.get_wallet_by_user_id(db, user_id)
        if not wallet or not wallet.accounts:
            return None
        active_accounts = [acc for acc in wallet.accounts if getattr(acc, "status", None) == "ACTIVE"]
        return active_accounts[0] if active_accounts else wallet.accounts[0]

    @classmethod
    def _canonical_currency(cls, hint: str | None) -> str:
        if not hint:
            return ""
        normalized = cls._normalize_text(hint)
        return cls.CURRENCY_ALIASES.get(normalized, hint.upper())

    @classmethod
    def _resolve_bank(cls, db: Session, bank_hint: str | int | None):
        if bank_hint is None:
            return None
        if isinstance(bank_hint, int) or str(bank_hint).isdigit():
            return BankingService.get_bank_by_id(db, int(bank_hint))
        text = str(bank_hint).strip().lower()
        banks = BankingService.list_banks(db, is_active=True)
        for bank in banks:
            name = (bank.name or "").strip().lower()
            code = (bank.code or "").strip().lower()
            if text == name or text == code or text in name:
                return bank
        return None

    @staticmethod
    def _summary_transactions(items: Iterable[dict[str, Any]]) -> str:
        rows = list(items)
        if not rows:
            return "لا توجد عمليات مطابقة."
        lines = []
        for tx in rows[:10]:
            lines.append(
                f"- رقم العملية: {tx.get('transaction_id')} | النوع: {tx.get('type')} | الحالة: {tx.get('status')} | المبلغ: {tx.get('amount')} | العملة: {tx.get('currency_id')}"
            )
        if len(rows) > 10:
            lines.append(f"... وهناك {len(rows) - 10} عمليات إضافية.")
        return "\n".join(lines)

    @staticmethod
    def _clean(params: dict[str, Any]) -> dict[str, Any]:
        return {k: v for k, v in params.items() if v is not None}
