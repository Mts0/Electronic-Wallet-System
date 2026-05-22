import random
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

SENDGRID_API_KEY = "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"   # مؤقت للتجربة فقط (لا ترفعه GitHub)
FROM_EMAIL = "mohammedabraij@gmail.com" # لازم يكون Verified في SendGrid
TO_EMAIL = "mohammed.braij@gmail.com"   # جرّب لنفسك أولًا

otp = str(random.randint(100000, 999999))

msg = Mail(
    from_email=FROM_EMAIL,
    to_emails=TO_EMAIL,
    subject="OTP Test",
    plain_text_content=f"Your OTP is: {otp}"
)

sg = SendGridAPIClient(SENDGRID_API_KEY)
resp = sg.send(msg)

print("Status:", resp.status_code)
