import re
import phonenumbers
from fastapi import Request

def validate_phone_number(phone_number: str) -> bool:
    """التحقق من صحة رقم الهاتف"""
    try:
        parsed_number = phonenumbers.parse(phone_number, None)
        return phonenumbers.is_valid_number(parsed_number)
    except:
        return False

def validate_password(password: str) -> bool:
    """التحقق من قوة كلمة المرور"""
    if len(password) < 8:
        return False
    if not re.search(r"[A-Z]", password):
        return False
    if not re.search(r"[a-z]", password):
        return False
    if not re.search(r"[0-9]", password):
        return False
    if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
        return False
    return True

def get_client_ip(request: Request) -> str:
    """الحصول على IP العميل"""
    if "x-forwarded-for" in request.headers:
        return request.headers["x-forwarded-for"].split(",")[0]
    return request.client.host

def get_device_info(request: Request) -> str:
    """الحصول على معلومات جهاز العميل"""
    user_agent = request.headers.get("user-agent", "Unknown")
    return f"{user_agent}"