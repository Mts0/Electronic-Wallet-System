from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.engine import Engine

# from apps.init import Base
Base = declarative_base()
"""
engine = create_engine("postgresql+psycopg2://postgres:Mohammed_123@localhost/WalletsDB")
connection = engine.connect()
print("تم الاتصال بنجاح!")
connection.close()"""


# سيكون هذا مؤقتاً للتطوير، في production نستخدم متغيرات البيئة
DATABASE_URL = "postgresql://postgres:Mohammed_123@localhost/WalletsDB"

engine = create_engine(DATABASE_URL, echo=True)

# إنشاء جلسة قاعدة البيانات
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)



# القاعدة للنماذج

"""
def init_db():
    Base.metadata.create_all(bind=engine)
"""



def get_session():
    """الحصول على جلسة قاعدة البيانات"""
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
