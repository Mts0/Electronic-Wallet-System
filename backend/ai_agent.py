import json
import os
from typing import Any, Dict, List, Optional

import requests
from groq import Groq


GROQ_API_KEY = os.getenv("GROQ_API_KEY", "98236429")
BASE_URL = os.getenv("WALLET_API_BASE_URL", "http://127.0.0.1:8000")
MODEL_NAME = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")
TIMEOUT = int(os.getenv("WALLET_API_TIMEOUT", "30"))


SYSTEM_PROMPT = """
أنت وكيل ذكي مرتبط فعليًا بنظام المحفظة الإلكترونية عبر واجهات API حقيقية.

قواعدك الصارمة:
1) لا تخترع أي بيانات مفقودة.
2) إذا احتاجت العملية معلومة ناقصة، اسأل عنها بوضوح وباختصار.
3) قبل تنفيذ أي عملية مالية، استخدم الأدوات المناسبة لجلب البيانات اللازمة عند الإمكان.
4) إذا كان المستخدم غير مسجل دخول، اطلب منه تسجيل الدخول أولًا أو نفذ أداة تسجيل الدخول إذا زودك بالبيانات.
5) عند الحاجة إلى account_id أو wallet_number أو currency_id، حاول الحصول عليها من النظام باستخدام الأدوات بدل طلبها مباشرة، إلا إذا تعذر ذلك.
6) استخدم العربية الفصحى الواضحة والمختصرة.
7) بعد تنفيذ العملية بنجاح، أخبر المستخدم بالنتيجة الفعلية القادمة من النظام.
8) عند فشل استدعاء API، اشرح الخطأ الحقيقي القادم من الخادم دون تهويل.

نقاط مهمة عن النظام:
- التحويل بين المحافظ يتم عبر /transactions/transfer ويتطلب غالبًا from_account_id و to_wallet_number و amount.
- شحن الرصيد يتم عبر /transactions/mobile-topup.
- الصرف بين العملات يتم عبر /transactions/exchange.
- السحب من الصراف يتم عبر /transactions/atm-withdraw.
- معلومات المحفظة والحسابات والعملات متاحة عبر /wallets.
- سجل العمليات متاح عبر /transactions/me.
""".strip()


def _safe_json(resp: requests.Response) -> Any:
    try:
        return resp.json()
    except Exception:
        return {"raw": resp.text}


class WalletAPIClient:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")
        self.access_token: Optional[str] = None
        self.refresh_token: Optional[str] = None

    def _headers(self) -> Dict[str, str]:
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        return headers

    def _request(self, method: str, path: str, json_data: Optional[dict] = None, params: Optional[dict] = None) -> dict:
        url = f"{self.base_url}{path}"
        response = requests.request(
            method=method,
            url=url,
            headers=self._headers(),
            json=json_data,
            params=params,
            timeout=TIMEOUT,
        )
        data = _safe_json(response)
        if response.ok:
            return {
                "success": True,
                "status_code": response.status_code,
                "data": data,
            }
        return {
            "success": False,
            "status_code": response.status_code,
            "error": data,
            "message": self._extract_error_message(data, response.text),
        }

    @staticmethod
    def _extract_error_message(data: Any, fallback: str) -> str:
        if isinstance(data, dict):
            if isinstance(data.get("detail"), str):
                return data["detail"]
            if isinstance(data.get("detail"), list):
                try:
                    return " | ".join(item.get("msg", str(item)) for item in data["detail"])
                except Exception:
                    return str(data["detail"])
            if isinstance(data.get("message"), str):
                return data["message"]
        return fallback.strip() or "حدث خطأ غير معروف"

    # ========= Auth =========
    def login(self, phone_number: Optional[str] = None, email: Optional[str] = None, password: str = "") -> dict:
        payload = {
            "phone_number": phone_number,
            "email": email,
            "password": password,
        }
        result = self._request("POST", "/auth/login", json_data=payload)
        if result["success"]:
            data = result["data"]
            self.access_token = data.get("access_token")
            self.refresh_token = data.get("refresh_token")
        return result

    def register(self, full_name: str, password: str, phone_number: str, email: Optional[str] = None) -> dict:
        payload = {
            "full_name": full_name,
            "phone_number": phone_number,
            "email": email,
            "password": password,
        }
        return self._request("POST", "/auth/register", json_data=payload)

    def request_otp(self, phone_number: str, verification_type: str) -> dict:
        payload = {"phone_number": phone_number, "verification_type": verification_type}
        return self._request("POST", "/auth/request-otp", json_data=payload)

    def verify_otp(self, phone_number: str, otp_code: str, verification_type: str) -> dict:
        payload = {
            "phone_number": phone_number,
            "otp_code": otp_code,
            "verification_type": verification_type,
        }
        return self._request("POST", "/auth/verify-otp", json_data=payload)

    def get_me(self) -> dict:
        return self._request("GET", "/auth/me")

    # ========= Wallet =========
    def get_wallet(self) -> dict:
        return self._request("GET", "/wallets/me")

    def list_wallet_accounts(self) -> dict:
        return self._request("GET", "/wallets/me/accounts")

    def list_currencies(self) -> dict:
        return self._request("GET", "/wallets/currencies")

    def create_wallet_account(self, currency_id: int, initial_balance: float = 0) -> dict:
        payload = {"currency_id": currency_id, "initial_balance": initial_balance}
        return self._request("POST", "/wallets/me/accounts", json_data=payload)

    def update_wallet_account_status(self, account_id: int, status: str) -> dict:
        payload = {"status": status}
        return self._request("PATCH", f"/wallets/me/accounts/{account_id}/status", json_data=payload)

    # ========= Transactions =========
    def list_transactions(self, limit: int = 20, status_filter: Optional[str] = None, type_filter: Optional[str] = None) -> dict:
        params = {"limit": limit}
        if status_filter:
            params["status_filter"] = status_filter
        if type_filter:
            params["type_filter"] = type_filter
        return self._request("GET", "/transactions/me", params=params)

    def list_failed_transactions(self, limit: int = 20) -> dict:
        return self._request("GET", "/transactions/me/failed", params={"limit": limit})

    def transfer(self, from_account_id: int, to_wallet_number: str, amount: float, notes: Optional[str] = None) -> dict:
        payload = {
            "from_account_id": from_account_id,
            "to_wallet_number": to_wallet_number,
            "amount": amount,
            "notes": notes,
        }
        return self._request("POST", "/transactions/transfer", json_data=payload)

    def mobile_topup(self, amount: float, phone_number: str, package_code: Optional[str] = None, notes: Optional[str] = None) -> dict:
        payload = {
            "amount": amount,
            "phone_number": phone_number,
            "package_code": package_code,
            "notes": notes,
        }
        return self._request("POST", "/transactions/mobile-topup", json_data=payload)

    def exchange(self, from_account_id: int, to_account_id: int, from_amount: float, notes: Optional[str] = None) -> dict:
        payload = {
            "from_account_id": from_account_id,
            "to_account_id": to_account_id,
            "from_amount": from_amount,
            "notes": notes,
        }
        return self._request("POST", "/transactions/exchange", json_data=payload)

    def atm_withdraw(self, account_id: int, amount: float, bank_id: int, message: Optional[str] = None) -> dict:
        payload = {
            "account_id": account_id,
            "amount": amount,
            "bank_id": bank_id,
            "message": message,
        }
        return self._request("POST", "/transactions/atm-withdraw", json_data=payload)

    # ========= Helpers =========
    def resolve_account_id(self, preferred_currency_id: Optional[int] = None) -> dict:
        accounts_result = self.list_wallet_accounts()
        if not accounts_result["success"]:
            return accounts_result

        accounts = accounts_result["data"] or []
        if preferred_currency_id is not None:
            for acc in accounts:
                currency = acc.get("currency") or {}
                if currency.get("currency_id") == preferred_currency_id and acc.get("status") == "ACTIVE":
                    return {"success": True, "status_code": 200, "data": acc}

        for acc in accounts:
            if acc.get("status") == "ACTIVE":
                return {"success": True, "status_code": 200, "data": acc}

        return {
            "success": False,
            "status_code": 404,
            "message": "لم يتم العثور على حساب محفظة نشط مناسب",
            "error": {"detail": "لا يوجد حساب نشط"},
        }

    def resolve_exchange_accounts(self, from_currency_id: int, to_currency_id: int) -> dict:
        accounts_result = self.list_wallet_accounts()
        if not accounts_result["success"]:
            return accounts_result

        from_acc = None
        to_acc = None
        for acc in accounts_result["data"] or []:
            currency = acc.get("currency") or {}
            cid = currency.get("currency_id")
            if cid == from_currency_id and acc.get("status") == "ACTIVE":
                from_acc = acc
            if cid == to_currency_id and acc.get("status") == "ACTIVE":
                to_acc = acc

        if not from_acc:
            return {
                "success": False,
                "status_code": 404,
                "message": f"لا يوجد حساب نشط للعملة المصدر ذات المعرّف {from_currency_id}",
                "error": {"detail": "from account not found"},
            }
        if not to_acc:
            return {
                "success": False,
                "status_code": 404,
                "message": f"لا يوجد حساب نشط للعملة الهدف ذات المعرّف {to_currency_id}",
                "error": {"detail": "to account not found"},
            }
        return {
            "success": True,
            "status_code": 200,
            "data": {
                "from_account_id": from_acc["account_id"],
                "to_account_id": to_acc["account_id"],
            },
        }


api = WalletAPIClient(BASE_URL)


def tool_login_user(phone_number: Optional[str] = None, email: Optional[str] = None, password: str = "") -> str:
    return json.dumps(api.login(phone_number=phone_number, email=email, password=password), ensure_ascii=False)


def tool_register_user(full_name: str, phone_number: str, password: str, email: Optional[str] = None) -> str:
    return json.dumps(api.register(full_name=full_name, phone_number=phone_number, password=password, email=email), ensure_ascii=False)


def tool_request_otp(phone_number: str, verification_type: str) -> str:
    return json.dumps(api.request_otp(phone_number=phone_number, verification_type=verification_type), ensure_ascii=False)


def tool_verify_otp(phone_number: str, otp_code: str, verification_type: str) -> str:
    return json.dumps(api.verify_otp(phone_number=phone_number, otp_code=otp_code, verification_type=verification_type), ensure_ascii=False)


def tool_get_profile() -> str:
    return json.dumps(api.get_me(), ensure_ascii=False)


def tool_get_wallet() -> str:
    return json.dumps(api.get_wallet(), ensure_ascii=False)


def tool_list_wallet_accounts() -> str:
    return json.dumps(api.list_wallet_accounts(), ensure_ascii=False)


def tool_list_currencies() -> str:
    return json.dumps(api.list_currencies(), ensure_ascii=False)


def tool_create_wallet_account(currency_id: int, initial_balance: float = 0) -> str:
    return json.dumps(api.create_wallet_account(currency_id=currency_id, initial_balance=initial_balance), ensure_ascii=False)


def tool_update_wallet_account_status(account_id: int, status: str) -> str:
    return json.dumps(api.update_wallet_account_status(account_id=account_id, status=status), ensure_ascii=False)


def tool_list_transactions(limit: int = 20, status_filter: Optional[str] = None, type_filter: Optional[str] = None) -> str:
    return json.dumps(api.list_transactions(limit=limit, status_filter=status_filter, type_filter=type_filter), ensure_ascii=False)


def tool_list_failed_transactions(limit: int = 20) -> str:
    return json.dumps(api.list_failed_transactions(limit=limit), ensure_ascii=False)


def tool_transfer_money(to_wallet_number: str, amount: float, from_account_id: Optional[int] = None, currency_id: Optional[int] = None, notes: Optional[str] = None) -> str:
    if from_account_id is None:
        resolved = api.resolve_account_id(preferred_currency_id=currency_id)
        if not resolved["success"]:
            return json.dumps(resolved, ensure_ascii=False)
        from_account_id = resolved["data"]["account_id"]
    result = api.transfer(from_account_id=from_account_id, to_wallet_number=to_wallet_number, amount=amount, notes=notes)
    return json.dumps(result, ensure_ascii=False)


def tool_mobile_topup(phone_number: str, amount: float, package_code: Optional[str] = None, notes: Optional[str] = None) -> str:
    return json.dumps(api.mobile_topup(amount=amount, phone_number=phone_number, package_code=package_code, notes=notes), ensure_ascii=False)


def tool_exchange_currency(from_amount: float, from_account_id: Optional[int] = None, to_account_id: Optional[int] = None,
                           from_currency_id: Optional[int] = None, to_currency_id: Optional[int] = None,
                           notes: Optional[str] = None) -> str:
    if from_account_id is None or to_account_id is None:
        if from_currency_id is None or to_currency_id is None:
            return json.dumps({
                "success": False,
                "status_code": 400,
                "message": "يلزم تحديد from_account_id و to_account_id أو تحديد from_currency_id و to_currency_id",
            }, ensure_ascii=False)
        resolved = api.resolve_exchange_accounts(from_currency_id=from_currency_id, to_currency_id=to_currency_id)
        if not resolved["success"]:
            return json.dumps(resolved, ensure_ascii=False)
        from_account_id = resolved["data"]["from_account_id"]
        to_account_id = resolved["data"]["to_account_id"]

    result = api.exchange(
        from_account_id=from_account_id,
        to_account_id=to_account_id,
        from_amount=from_amount,
        notes=notes,
    )
    return json.dumps(result, ensure_ascii=False)


def tool_atm_withdraw(amount: float, bank_id: int, account_id: Optional[int] = None, currency_id: Optional[int] = None,
                      message: Optional[str] = None) -> str:
    if account_id is None:
        resolved = api.resolve_account_id(preferred_currency_id=currency_id)
        if not resolved["success"]:
            return json.dumps(resolved, ensure_ascii=False)
        account_id = resolved["data"]["account_id"]
    result = api.atm_withdraw(account_id=account_id, amount=amount, bank_id=bank_id, message=message)
    return json.dumps(result, ensure_ascii=False)


TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "tool_login_user",
            "description": "تسجيل دخول المستخدم إلى نظام المحفظة عبر API الحقيقي.",
            "parameters": {
                "type": "object",
                "properties": {
                    "phone_number": {"type": "string"},
                    "email": {"type": "string"},
                    "password": {"type": "string"},
                },
                "required": ["password"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_register_user",
            "description": "تسجيل مستخدم جديد في النظام.",
            "parameters": {
                "type": "object",
                "properties": {
                    "full_name": {"type": "string"},
                    "phone_number": {"type": "string"},
                    "email": {"type": "string"},
                    "password": {"type": "string"},
                },
                "required": ["full_name", "phone_number", "password"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_request_otp",
            "description": "طلب OTP للتسجيل أو إعادة كلمة المرور. القيم المتوقعة للتحقق مثل REGISTER أو PASSWORD_RESET.",
            "parameters": {
                "type": "object",
                "properties": {
                    "phone_number": {"type": "string"},
                    "verification_type": {"type": "string"},
                },
                "required": ["phone_number", "verification_type"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_verify_otp",
            "description": "التحقق من OTP للتسجيل أو استعادة كلمة المرور.",
            "parameters": {
                "type": "object",
                "properties": {
                    "phone_number": {"type": "string"},
                    "otp_code": {"type": "string"},
                    "verification_type": {"type": "string"},
                },
                "required": ["phone_number", "otp_code", "verification_type"],
            },
        },
    },
    {"type": "function", "function": {"name": "tool_get_profile", "description": "جلب ملف المستخدم الحالي.", "parameters": {"type": "object", "properties": {}}}},
    {"type": "function", "function": {"name": "tool_get_wallet", "description": "جلب المحفظة الحالية مع الحسابات.", "parameters": {"type": "object", "properties": {}}}},
    {"type": "function", "function": {"name": "tool_list_wallet_accounts", "description": "عرض حسابات المحفظة الحالية.", "parameters": {"type": "object", "properties": {}}}},
    {"type": "function", "function": {"name": "tool_list_currencies", "description": "عرض العملات الفعالة.", "parameters": {"type": "object", "properties": {}}}},
    {
        "type": "function",
        "function": {
            "name": "tool_create_wallet_account",
            "description": "إضافة حساب عملة جديد داخل محفظة المستخدم.",
            "parameters": {
                "type": "object",
                "properties": {
                    "currency_id": {"type": "integer"},
                    "initial_balance": {"type": "number"},
                },
                "required": ["currency_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_update_wallet_account_status",
            "description": "تغيير حالة حساب محفظة مثل ACTIVE أو SUSPENDED أو CLOSED.",
            "parameters": {
                "type": "object",
                "properties": {
                    "account_id": {"type": "integer"},
                    "status": {"type": "string"},
                },
                "required": ["account_id", "status"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_transfer_money",
            "description": "تحويل أموال إلى رقم محفظة فعلي. إذا لم يوجد from_account_id يمكن محاولة استنتاجه من حسابات المستخدم، خاصة عند تزويد currency_id.",
            "parameters": {
                "type": "object",
                "properties": {
                    "to_wallet_number": {"type": "string"},
                    "amount": {"type": "number"},
                    "from_account_id": {"type": "integer"},
                    "currency_id": {"type": "integer"},
                    "notes": {"type": "string"},
                },
                "required": ["to_wallet_number", "amount"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_mobile_topup",
            "description": "شحن رصيد جوال فعلي عبر API.",
            "parameters": {
                "type": "object",
                "properties": {
                    "phone_number": {"type": "string"},
                    "amount": {"type": "number"},
                    "package_code": {"type": "string"},
                    "notes": {"type": "string"},
                },
                "required": ["phone_number", "amount"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_exchange_currency",
            "description": "صرف بين حسابي عملتين. يمكن تمرير account ids مباشرة أو تمرير from_currency_id و to_currency_id لمحاولة إيجاد الحسابين تلقائيًا.",
            "parameters": {
                "type": "object",
                "properties": {
                    "from_amount": {"type": "number"},
                    "from_account_id": {"type": "integer"},
                    "to_account_id": {"type": "integer"},
                    "from_currency_id": {"type": "integer"},
                    "to_currency_id": {"type": "integer"},
                    "notes": {"type": "string"},
                },
                "required": ["from_amount"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_atm_withdraw",
            "description": "إنشاء طلب سحب من صراف عبر البنك. يتطلب bank_id ومبلغًا، ويمكن استنتاج account_id من العملة إذا توفر currency_id.",
            "parameters": {
                "type": "object",
                "properties": {
                    "amount": {"type": "number"},
                    "bank_id": {"type": "integer"},
                    "account_id": {"type": "integer"},
                    "currency_id": {"type": "integer"},
                    "message": {"type": "string"},
                },
                "required": ["amount", "bank_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_list_transactions",
            "description": "عرض عمليات المستخدم مع فلاتر اختيارية.",
            "parameters": {
                "type": "object",
                "properties": {
                    "limit": {"type": "integer"},
                    "status_filter": {"type": "string"},
                    "type_filter": {"type": "string"},
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "tool_list_failed_transactions",
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


AVAILABLE_FUNCTIONS = {
    "tool_login_user": tool_login_user,
    "tool_register_user": tool_register_user,
    "tool_request_otp": tool_request_otp,
    "tool_verify_otp": tool_verify_otp,
    "tool_get_profile": tool_get_profile,
    "tool_get_wallet": tool_get_wallet,
    "tool_list_wallet_accounts": tool_list_wallet_accounts,
    "tool_list_currencies": tool_list_currencies,
    "tool_create_wallet_account": tool_create_wallet_account,
    "tool_update_wallet_account_status": tool_update_wallet_account_status,
    "tool_transfer_money": tool_transfer_money,
    "tool_mobile_topup": tool_mobile_topup,
    "tool_exchange_currency": tool_exchange_currency,
    "tool_atm_withdraw": tool_atm_withdraw,
    "tool_list_transactions": tool_list_transactions,
    "tool_list_failed_transactions": tool_list_failed_transactions,
}


class WalletAIAgent:
    def __init__(self):
        if not GROQ_API_KEY:
            raise ValueError("يرجى ضبط المتغير البيئي GROQ_API_KEY قبل تشغيل الوكيل")
        self.client = Groq(api_key=GROQ_API_KEY)
        self.chat_history: List[Dict[str, Any]] = [
            {"role": "system", "content": SYSTEM_PROMPT}
        ]

    def ask(self, user_text: str) -> str:
        self.chat_history.append({"role": "user", "content": user_text})

        while True:
            response = self.client.chat.completions.create(
                model=MODEL_NAME,
                messages=self.chat_history,
                tools=TOOLS,
                tool_choice="auto",
            )
            msg = response.choices[0].message

            assistant_msg: Dict[str, Any] = {
                "role": msg.role,
                "content": msg.content or "",
            }
            if msg.tool_calls:
                assistant_msg["tool_calls"] = msg.tool_calls
            self.chat_history.append(assistant_msg)

            if not msg.tool_calls:
                return msg.content or ""

            for tool_call in msg.tool_calls:
                func_name = tool_call.function.name
                raw_args = tool_call.function.arguments or "{}"
                try:
                    args = json.loads(raw_args)
                except json.JSONDecodeError:
                    args = {}

                func = AVAILABLE_FUNCTIONS.get(func_name)
                if not func:
                    tool_output = json.dumps({
                        "success": False,
                        "message": f"الدالة {func_name} غير معرفة"
                    }, ensure_ascii=False)
                else:
                    try:
                        tool_output = func(**args)
                    except Exception as exc:
                        tool_output = json.dumps({
                            "success": False,
                            "message": f"خطأ أثناء تنفيذ {func_name}: {str(exc)}"
                        }, ensure_ascii=False)

                self.chat_history.append(
                    {
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "name": func_name,
                        "content": tool_output,
                    }
                )


if __name__ == "__main__":
    print("--- وكيل المحفظة الذكي المرتبط بـ FastAPI ---")
    print("BASE_URL =", BASE_URL)
    print("اكتب 'خروج' للإنهاء")

    try:
        agent = WalletAIAgent()
    except Exception as e:
        print(f"فشل بدء الوكيل: {e}")
        raise SystemExit(1)

    while True:
        user_input = input("\n[أنت]: ").strip()
        if user_input.lower() in {"خروج", "exit", "quit"}:
            break
        try:
            reply = agent.ask(user_input)
            print(f"[الوكيل]: {reply}")
        except Exception as e:
            print(f"[خطأ]: {e}")
