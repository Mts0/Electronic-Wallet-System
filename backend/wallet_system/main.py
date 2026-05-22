from apps.init import *
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from apps.core.database import engine
from apps.auth.routes import router as auth_router
from apps.wallets.routes import router as wallet_router
from apps.transactions.routes import router as transaction_router
from apps.KYC.routes import router as kyc_router
from apps.Favorites.routes import router as favorites_router
from apps.staff.routes import router as staff_router
from apps.FraudAndReport.routes import router as fraud_router
from apps.ConsumerAPI.routes import router as consumerAPI
from apps.ExternalAPI.routes import router as externalAPI
from apps.SystemSetting.routes import router as systemSetting
from apps.Banking.routes import router as banking
from apps.ExchangeRates.routes import router as exchangeRate
from apps.Support.routes import router as support
from apps.agent.routes import router as agent_router

import apps.auth.models  # لضمان إنشاء النماذج


@asynccontextmanager  # في مشكلة هنا ضروري المراجعة
async def lifespan(app: FastAPI):
    # تهيئة قاعدة البيانات عند بدء التشغيل
    # init_db()
    yield
    # تنظيف عند إيقاف التطبيق
    engine.dispose()


app = FastAPI(
    title="Wallet System APIs",
    description="واجهة برمجة نظام المحفظة الإلكترونية",
    version="1.0.1",
    lifespan=lifespan
)

# إعدادات CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# تضمين المسارات
app.include_router(auth_router)
app.include_router(transaction_router)
app.include_router(wallet_router)
app.include_router(kyc_router)
app.include_router(favorites_router)
app.include_router(staff_router)
app.include_router(fraud_router)
app.include_router(consumerAPI)
app.include_router(externalAPI)
app.include_router(systemSetting)
app.include_router(banking)
app.include_router(exchangeRate)
app.include_router(support)
app.include_router(agent_router)


@app.get("/")
def read_root():
    return {"message": "مرحباً بك في نظام المصادقة"}


@app.get("/health")
def health_check():
    return {"status": "healthy", "message": "API is working correctly"}


"""if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)"""
