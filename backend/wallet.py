import os
import json
from typing import Any, Dict, List, Optional

import requests
from groq import Groq


# ===== إعدادات مباشرة داخل الملف للتجربة =====
# عدّل هذه القيم مباشرة بدل استخدام أوامر set في النظام.
GROQ_API_KEY = "98236429"
WALLET_API_BASE_URL = "http://127.0.0.1:8000"
WALLET_ACCESS_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzk1Mzg2Mzk1fQ.-9LnWHsBgoxpmDo3cYnO8Wfqzvs4ejxzDCGcCKoxlFs"

# يمكن أيضًا القراءة من متغيرات البيئة إن وُجدت، لكن هذا اختياري فقط.
GROQ_API_KEY = os.getenv("GROQ_API_KEY", GROQ_API_KEY)
WALLET_API_BASE_URL = os.getenv("WALLET_API_BASE_URL", WALLET_API_BASE_URL)
WALLET_ACCESS_TOKEN = os.getenv("WALLET_ACCESS_TOKEN", WALLET_ACCESS_TOKEN)

client = Groq(api_key=GROQ_API_KEY) if GROQ_API_KEY else None


SYSTEM_PROMPT = """
أنت وكيل ذكي لنظام محفظة إلكترونية.

مهمتك تنفيذ 6 وظائف فقط عبر أدوات النظام الفعلية:
1) تحويل الأموال
2) شحن رصيد الجوال
3) الصرف بين العملات
4) طلب سحب من الصراف
5) عرض العمليات
6) عرض العمليات الفاشلة

قواعد العمل:
- رد دائمًا بالعربية.
- لا تنفذ أي عملية بدون البيانات الأساسية المطلوبة.
- لا تخترع أي قيمة غير موجودة.
- إذا نقصت معلومة فاطلبها بوضوح وباختصار.
- إذا توفرت المعلومات الكافية فاستدعِ الأداة المناسبة مباشرة.
- عند عرض العمليات، لخّص أهم المعلومات بشكل واضح.

متطلبات كل عملية:
- تحويل الأموال: المبلغ + رقم محفظة المستلم، ويمكنك تحديد الحساب المرسل تلقائيًا من حسابات المستخدم إذا أمكن.
- شحن رصيد الجوال: رقم الهاتف + المبلغ.
- الصرف بين العملات: المبلغ + العملة المصدر + العملة الهدف.
- طلب سحب من الصراف: المبلغ + البنك + العملة إن لزم.
- عرض العمليات: يمكن قبول limit أو status أو type.
- عرض العمليات الفاشلة: يمكن قبول limit فقط.
"""


def _clean_base_url(url: str) -> str:
    return url.rstrip("/")


class WalletAPI:
    def __init__(self, base_url: str, token: str):
        self.base_url = _clean_base_url(base_url)
        self.token = token

    @property
    def headers(self) -> Dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        return headers

    def _handle_response(self, response: requests.Response) -> Any:
        try:
            data = response.json()
        except Exception:
            data = response.text

        if not response.ok:
            raise Exception(f"API {response.status_code}: {data}")
        return data

    def get(self, path: str, params: Optional[dict] = None) -> Any:
        response = requests.get(
            f"{self.base_url}{path}", headers=self.headers, params=params, timeout=30
        )
        return self._handle_response(response)

    def post(self, path: str, payload: dict) -> Any:
        response = requests.post(
            f"{self.base_url}{path}", headers=self.headers, json=payload, timeout=30
        )
        return self._handle_response(response)

    # ===== helpers داخلية فقط =====
    def get_wallet_accounts(self) -> List[dict]:
        return self.get("/wallets/me/accounts")

    def get_currencies(self) -> List[dict]:
        return self.get("/wallets/currencies")

    def get_banks(self) -> List[dict]:
        # endpoint يتطلب صلاحية staff حسب المشروع؛ سنحاول، وإن فشل نعيد []
        try:
            return self.get("/banking/banks")
        except Exception:
            return []

    def find_account_by_currency(self, currency_name_or_symbol: Optional[str]) -> Optional[dict]:
        accounts = self.get_wallet_accounts()
        if not currency_name_or_symbol:
            return accounts[0] if accounts else None

        target = currency_name_or_symbol.strip().lower()
        for acc in accounts:
            cur = acc.get("currency") or {}
            name = str(cur.get("name", "")).strip().lower()
            symbol = str(cur.get("symbol", "")).strip().lower()
            if target in {name, symbol}:
                return acc
        return None

    def resolve_bank_id(self, bank_name_or_id: Any) -> int:
        if isinstance(bank_name_or_id, int):
            return bank_name_or_id
        text = str(bank_name_or_id).strip()
        if text.isdigit():
            return int(text)

        banks = self.get_banks()
        low = text.lower()
        for bank in banks:
            name = str(bank.get("name", "")).lower()
            code = str(bank.get("code", "")).lower()
            if low == name or low == code or low in name:
                return int(bank["bank_id"])
        raise Exception("تعذر تحديد البنك. أرسل اسم البنك المطابق للنظام أو bank_id.")

    # ===== الوظائف الست =====
    def transfer_money(self, amount: float, to_wallet_number: str, notes: Optional[str] = None,
                       from_currency: Optional[str] = None, from_account_id: Optional[int] = None) -> Any:
        account_id = from_account_id
        if not account_id:
            account = self.find_account_by_currency(from_currency)
            if not account:
                raise Exception("تعذر تحديد حساب الإرسال. أرسل العملة أو from_account_id.")
            account_id = int(account["account_id"])

        payload = {
            "from_account_id": account_id,
            "to_wallet_number": to_wallet_number,
            "amount": amount,
            "notes": notes,
        }
        return self.post("/transactions/transfer", payload)

    def mobile_topup(self, amount: float, phone_number: str,
                     package_code: Optional[str] = None, notes: Optional[str] = None) -> Any:
        payload = {
            "amount": amount,
            "phone_number": phone_number,
            "package_code": package_code,
            "notes": notes,
        }
        return self.post("/transactions/mobile-topup", payload)

    def exchange_currency(self, from_amount: float, from_currency: str, to_currency: str,
                          notes: Optional[str] = None,
                          from_account_id: Optional[int] = None, to_account_id: Optional[int] = None) -> Any:
        if not from_account_id:
            from_acc = self.find_account_by_currency(from_currency)
            if not from_acc:
                raise Exception("تعذر تحديد حساب العملة المصدر.")
            from_account_id = int(from_acc["account_id"])

        if not to_account_id:
            to_acc = self.find_account_by_currency(to_currency)
            if not to_acc:
                raise Exception("تعذر تحديد حساب العملة الهدف. يجب أن يكون للمستخدم حساب بهذه العملة.")
            to_account_id = int(to_acc["account_id"])

        payload = {
            "from_account_id": from_account_id,
            "to_account_id": to_account_id,
            "from_amount": from_amount,
            "notes": notes,
        }
        return self.post("/transactions/exchange", payload)

    def atm_withdraw_request(self, amount: float, bank: Any,
                             currency: Optional[str] = None,
                             message: Optional[str] = None,
                             account_id: Optional[int] = None) -> Any:
        if not account_id:
            account = self.find_account_by_currency(currency)
            if not account:
                raise Exception("تعذر تحديد الحساب المطلوب السحب منه.")
            account_id = int(account["account_id"])

        bank_id = self.resolve_bank_id(bank)
        payload = {
            "account_id": account_id,
            "amount": amount,
            "bank_id": bank_id,
            "message": message,
        }
        return self.post("/transactions/atm-withdraw", payload)

    def list_transactions(self, limit: int = 20,
                          status_filter: Optional[str] = None,
                          type_filter: Optional[str] = None) -> Any:
        params = {"limit": limit}
        if status_filter:
            params["status_filter"] = status_filter
        if type_filter:
            params["type_filter"] = type_filter
        return self.get("/transactions/me", params=params)

    def list_failed_transactions(self, limit: int = 20) -> Any:
        return self.get("/transactions/me/failed", params={"limit": limit})


api = WalletAPI(WALLET_API_BASE_URL, WALLET_ACCESS_TOKEN)


def _summary_transactions(items: List[dict]) -> str:
    if not items:
        return "لا توجد عمليات مطابقة."

    lines = []
    for tx in items[:10]:
        lines.append(
            f"- رقم العملية: {tx.get('transaction_id')} | النوع: {tx.get('type')} | الحالة: {tx.get('status')} | المبلغ: {tx.get('amount')} | العملة: {tx.get('currency_id')}"
        )
    if len(items) > 10:
        lines.append(f"... وهناك {len(items) - 10} عمليات إضافية.")
    return "\n".join(lines)


def tool_transfer_money(amount: float, to_wallet_number: str, notes: Optional[str] = None,
                        from_currency: Optional[str] = None, from_account_id: Optional[int] = None) -> str:
    result = api.transfer_money(
        amount=amount,
        to_wallet_number=to_wallet_number,
        notes=notes,
        from_currency=from_currency,
        from_account_id=from_account_id,
    )
    tx = result.get("transaction", {})
    return json.dumps(
        {
            "message": "تم تنفيذ التحويل بنجاح",
            "transaction_id": tx.get("transaction_id"),
            "status": tx.get("status"),
            "amount": tx.get("amount"),
            "to_wallet_number": result.get("to_wallet_number"),
            "to_user_name": result.get("to_user_name"),
        },
        ensure_ascii=False,
    )


def tool_mobile_topup(amount: float, phone_number: str,
                      package_code: Optional[str] = None, notes: Optional[str] = None) -> str:
    result = api.mobile_topup(amount=amount, phone_number=phone_number, package_code=package_code, notes=notes)
    tx = result.get("transaction", {})
    return json.dumps(
        {
            "message": "تم تنفيذ شحن الرصيد بنجاح",
            "transaction_id": tx.get("transaction_id"),
            "status": tx.get("status"),
            "amount": tx.get("amount"),
            "phone_number": result.get("phone_number"),
            "transaction_ref": result.get("transaction_ref"),
        },
        ensure_ascii=False,
    )


def tool_exchange_currency(from_amount: float, from_currency: str, to_currency: str,
                           notes: Optional[str] = None,
                           from_account_id: Optional[int] = None, to_account_id: Optional[int] = None) -> str:
    result = api.exchange_currency(
        from_amount=from_amount,
        from_currency=from_currency,
        to_currency=to_currency,
        notes=notes,
        from_account_id=from_account_id,
        to_account_id=to_account_id,
    )
    tx = result.get("transaction", {})
    return json.dumps(
        {
            "message": "تم تنفيذ الصرف بنجاح",
            "transaction_id": tx.get("transaction_id"),
            "status": tx.get("status"),
            "from_amount": tx.get("amount"),
            "to_amount": result.get("to_amount"),
            "exchange_rate": result.get("exchange_rate"),
            "from_currency": result.get("from_currency"),
            "to_currency": result.get("to_currency"),
        },
        ensure_ascii=False,
    )


def tool_atm_withdraw_request(amount: float, bank: Any,
                              currency: Optional[str] = None,
                              message: Optional[str] = None,
                              account_id: Optional[int] = None) -> str:
    result = api.atm_withdraw_request(
        amount=amount,
        bank=bank,
        currency=currency,
        message=message,
        account_id=account_id,
    )
    return json.dumps(
        {
            "message": "تم إنشاء طلب السحب من الصراف بنجاح",
            "request_id": result.get("request_id"),
            "transaction_id": result.get("transaction_id"),
            "bank_name": result.get("bank_name"),
            "amount": result.get("amount"),
            "code": result.get("code"),
            "pin_code": result.get("pin_code"),
            "expires_at": result.get("expires_at"),
            "status": result.get("status"),
        },
        ensure_ascii=False,
    )


def tool_list_transactions(limit: int = 20,
                           status_filter: Optional[str] = None,
                           type_filter: Optional[str] = None) -> str:
    result = api.list_transactions(limit=limit, status_filter=status_filter, type_filter=type_filter)
    return json.dumps(
        {
            "message": "تم جلب العمليات",
            "count": len(result),
            "summary": _summary_transactions(result),
            "items": result,
        },
        ensure_ascii=False,
    )


def tool_list_failed_transactions(limit: int = 20) -> str:
    result = api.list_failed_transactions(limit=limit)
    return json.dumps(
        {
            "message": "تم جلب العمليات الفاشلة",
            "count": len(result),
            "summary": _summary_transactions(result),
            "items": result,
        },
        ensure_ascii=False,
    )


TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "transfer_money",
            "description": "تحويل أموال إلى محفظة أخرى باستخدام رقم محفظة المستلم.",
            "parameters": {
                "type": "object",
                "properties": {
                    "amount": {"type": "number"},
                    "to_wallet_number": {"type": "string"},
                    "notes": {"type": "string"},
                    "from_currency": {"type": "string", "description": "اختياري مثل YER أو USD أو اسم العملة"},
                    "from_account_id": {"type": "integer"},
                },
                "required": ["amount", "to_wallet_number"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "mobile_topup",
            "description": "شحن رصيد جوال باستخدام رقم الهاتف والمبلغ.",
            "parameters": {
                "type": "object",
                "properties": {
                    "amount": {"type": "number"},
                    "phone_number": {"type": "string"},
                    "package_code": {"type": "string"},
                    "notes": {"type": "string"},
                },
                "required": ["amount", "phone_number"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "exchange_currency",
            "description": "صرف مبلغ من عملة إلى عملة أخرى بين حسابات المستخدم.",
            "parameters": {
                "type": "object",
                "properties": {
                    "from_amount": {"type": "number"},
                    "from_currency": {"type": "string"},
                    "to_currency": {"type": "string"},
                    "notes": {"type": "string"},
                    "from_account_id": {"type": "integer"},
                    "to_account_id": {"type": "integer"},
                },
                "required": ["from_amount", "from_currency", "to_currency"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "atm_withdraw_request",
            "description": "إنشاء طلب سحب من الصراف وإرجاع كود وPIN السحب.",
            "parameters": {
                "type": "object",
                "properties": {
                    "amount": {"type": "number"},
                    "bank": {"anyOf": [{"type": "string"}, {"type": "integer"}]},
                    "currency": {"type": "string"},
                    "message": {"type": "string"},
                    "account_id": {"type": "integer"},
                },
                "required": ["amount", "bank"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_transactions",
            "description": "عرض عمليات المستخدم مع إمكان التصفية حسب الحالة أو النوع.",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {"type": "integer"},
                    "status_filter": {"type": "string", "description": "PENDING أو COMPLETED أو FAILED"},
                    "type_filter": {"type": "string", "description": "TRANSFER أو MOBILE_TOPUP أو ATM_WITHDRAW أو EXCHANGE"},
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_failed_transactions",
            "description": "عرض العمليات الفاشلة فقط.",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {"type": "integer"},
                },
            },
        },
    },
]


TOOL_FUNCTIONS = {
    "transfer_money": tool_transfer_money,
    "mobile_topup": tool_mobile_topup,
    "exchange_currency": tool_exchange_currency,
    "atm_withdraw_request": tool_atm_withdraw_request,
    "list_transactions": tool_list_transactions,
    "list_failed_transactions": tool_list_failed_transactions,
}


chat_history: List[Dict[str, Any]] = [{"role": "system", "content": SYSTEM_PROMPT}]


def wallet_ai_agent(user_text: str) -> str:
    if not client:
        return (
            "الوضع الحالي تجريبي، ولم يتم وضع GROQ_API_KEY داخل الملف بعد.\n"
            "يمكنك الآن تشغيل الربط اليدوي مع API بعد تعبئة القيم في أعلى الملف، "
            "أو إضافة المفتاح لتفعيل فهم الطلبات الذكي."
        )

    chat_history.append({"role": "user", "content": user_text})

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=chat_history,
        tools=TOOLS,
        tool_choice="auto",
    )

    message = response.choices[0].message
    assistant_msg = {"role": message.role, "content": message.content}
    if message.tool_calls:
        assistant_msg["tool_calls"] = message.tool_calls
    chat_history.append(assistant_msg)

    if not message.tool_calls:
        return message.content or ""

    for tool_call in message.tool_calls:
        name = tool_call.function.name
        args = json.loads(tool_call.function.arguments or "{}")
        func = TOOL_FUNCTIONS[name]
        tool_result = func(**args)
        chat_history.append(
            {
                "role": "tool",
                "tool_call_id": tool_call.id,
                "name": name,
                "content": tool_result,
            }
        )

    final_response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=chat_history,
    )
    final_text = final_response.choices[0].message.content or ""
    chat_history.append({"role": "assistant", "content": final_text})
    return final_text


if __name__ == "__main__":
    print("--- وكيل المحفظة الذكي (6 وظائف فقط) ---")
    print("تأكد من ضبط:")
    print("GROQ_API_KEY")
    print("WALLET_API_BASE_URL")
    print("WALLET_ACCESS_TOKEN")
    print("اكتب 'خروج' للإنهاء.\n")

    while True:
        user_input = input("[أنت]: ").strip()
        if user_input.lower() in {"خروج", "exit", "quit"}:
            break
        try:
            answer = wallet_ai_agent(user_input)
            print(f"[الوكيل]: {answer}\n")
        except Exception as exc:
            print(f"[خطأ]: {exc}\n")
