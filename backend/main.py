import json
from groq import Groq
from typing import List, Dict, Any

# إعداد العميل (تأكد من صحة المفتاح الخاص بك)
client = Groq(api_key="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")

# --- 1. بروتوكول التحقق والذاكرة الصارم ---
SYSTEM_PROMPT = """
أنت 'خبير التحقق والعمليات المالي' في نظام المحفظة الإلكترونية الذكي. 
مهمتك الأساسية هي إدارة الجلسة المالية بصرامة، وضمان تنفيذ العمليات فقط عند اكتمال كافة البيانات المطلوبة.

### أولاً: بروتوكول فحص البيانات (قبل التنفيذ)
قبل استدعاء أي دالة (Tool)، يجب عليك مطابقة مدخلات المستخدم (الحالية والسابقة في الذاكرة) مع المتغيرات المطلوبة (Required Parameters):
1. دالة (transfer_remittance): يمنع التنفيذ إلا بوجود (المبلغ الرقمي) و (اسم المستلم الصريح).
2. دالة (receive_remittance): يمنع التنفيذ إلا بوجود (رقم الكود الخاص بالحوالة).
3. دالة (pay_purchases): يمنع التنفيذ إلا بوجود (اسم المتجر/المحل) و (المبلغ المطلوب دفعه).
4. دالة (pay_bills): يمنع التنفيذ إلا بوجود (نوع الخدمة: كهرباء، ماء، إنترنت) و (قيمة الفاتورة).

### ثانياً: قواعد منع الهلوسة والذاكرة
1. الذاكرة التراكمية: إذا ذكر المستخدم معلومة في رسالة سابقة (مثلاً: المبلغ 5000)، فاحفظها في ذاكرتك. إذا ذكر في الرسالة التالية (المستلم: محمد)، قم بدمج المعلومتين واستدعِ الدالة فوراً.
2. منع التخمين الإجباري: يمنع منعاً باتاً اختراع أي بيانات لم يذكرها المستخدم. لا تخترع أسماء مستلمين، ولا تضع مبالغ افتراضية، ولا تولد أرقام حوالات من خيالك.
3. التوقف والطلب: إذا كانت العملية المالية المطلوبة تفتقر لأي بيان مطلوب، توقف عن استدعاء الدالة فوراً، وقم بالرد على المستخدم بسؤال مباشر وواضح لطلب المعلومة الناقصة (مثلاً: "إلى من تود تحويل مبلغ الـ 5000 ريال؟").

### ثالثاً: ضوابط الرد والتفاعل
1. الصياغة: رد دائماً باللغة العربية بلهجة مهذبة، مهنية، ومختصرة جداً.
2. الوضوح: عند طلب معلومة ناقصة، حدد بالضبط ما هو الناقص (المبلغ، المستلم، أو الكود).
3. التأكيد: بمجرد استدعاء الدالة بنجاح، انتظر تأكيد النظام ثم أبلغ المستخدم بانتهاء العملية.

أنت الآن في وضع 'التدقيق الصارم'. لا تنفذ أي حركة مالية دون اكتمال أركانها البرمجية.
"""

# --- 2. تعريف الأدوات (Tools) ---
tools = [
    {
        "type": "function",
        "function": {
            "name": "transfer_remittance",
            "description": "إرسال حوالة. تتطلب اسم المستلم والمبلغ.",
            "parameters": {
                "type": "object",
                "properties": {
                    "amount": {"type": "number", "description": "المبلغ"},
                    "recipient": {"type": "string", "description": "اسم المستلم"}
                },
                "required": ["amount", "recipient"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "receive_remittance",
            "description": "استلام حوالة. تتطلب رقم الكود.",
            "parameters": {
                "type": "object",
                "properties": {
                    "remittance_code": {"type": "string", "description": "رقم الكود"}
                },
                "required": ["remittance_code"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "pay_purchases",
            "description": "دفع للمتاجر. تتطلب اسم المتجر والمبلغ.",
            "parameters": {
                "type": "object",
                "properties": {
                    "store_name": {"type": "string", "description": "اسم المتجر"},
                    "amount": {"type": "number", "description": "المبلغ"}
                },
                "required": ["store_name", "amount"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "pay_bills",
            "description": "تسديد فواتير الخدمات. تتطلب نوع الفاتورة والقيمة.",
            "parameters": {
                "type": "object",
                "properties": {
                    "bill_type": {"type": "string", "description": "نوع الفاتورة (كهرباء، ماء، إنترنت)"},
                    "amount": {"type": "number"}
                },
                "required": ["bill_type", "amount"]
            }
        }
    }
]

# --- 3. إدارة الذاكرة ---
chat_history: List[Dict[str, Any]] = [
    {"role": "system", "content": SYSTEM_PROMPT}
]


def wallet_ai_agent(user_text):
    # إضافة رسالة المستخدم للذاكرة
    chat_history.append({"role": "user", "content": user_text})

    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=chat_history,
            tools=tools,
            tool_choice="auto"
        )

        response_message = response.choices[0].message

        # --- الحل الجذري لخطأ 400: بناء رسالة نظيفة للذاكرة ---
        # نقوم بأخذ الـ role والـ content والـ tool_calls فقط، ونتجاهل الـ annotations
        msg_to_append = {
            "role": response_message.role,
            "content": response_message.content,
        }
        if response_message.tool_calls:
            msg_to_append["tool_calls"] = response_message.tool_calls

        chat_history.append(msg_to_append)

        if response_message.tool_calls:
            for tool_call in response_message.tool_calls:
                func_name = tool_call.function.name
                args = json.loads(tool_call.function.arguments)

                print(f"\n✅ [توجيه برمي] تنفيذ عملية: {func_name}")
                print(f"📦 [التفاصيل]: {args}")

                # إغلاق حلقة الوظيفة في الذاكرة
                chat_history.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "name": func_name,
                    "content": "تمت العملية بنجاح في النظام المالي."
                })

                # رد نهائي من الـ AI بعد التنفيذ
                final_response = client.chat.completions.create(
                    model="llama-3.3-70b-versatile",
                    messages=chat_history
                )
                print(f"💬 رد النظام: {final_response.choices[0].message.content}")
                chat_history.append({"role": "assistant", "content": final_response.choices[0].message.content})
        else:
            print(f"💬 رد النظام: {response_message.content}")

    except Exception as e:
        print(f"❌ حدث خطأ: {e}")


# --- 4. تشغيل تفاعلي ---
if __name__ == "__main__":
    print("--- نظام المحفظة الذكي (V2) جاهز ---")
    print("(اكتب 'خروج' للإنهاء)")

    while True:
        user_input = input("\n[أنت]: ")
        if user_input.lower() in ['خروج', 'exit', 'quit']:
            break
        wallet_ai_agent(user_input)