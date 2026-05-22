#from sqlalchemy.orm import declarative_base

#from apps.core.database import Base
#Base = declarative_base()

from .auth.models import *
from .wallets.models import *
from .transactions.models import *
from .KYC.models import *
from .staff.models import *
from .SystemSetting.models import *
from .Security.models import *
from .Support.models import *
from .FraudAndReport.models import *
from .Favorites.models import *
from .ConsumerAPI.models import *
from .Banking.models import *
from .ExchangeRates.models import *
from .ExternalAPI.models import *  # ✅ Added external services

__all__ = [
    'Base',
    'User', 'Address', 'PasswordReset', 'Verification', 'UserSession', 'LoginTry', 'UserDevice',
    'Wallet', 'WalletAccount', 'Currency',
    'Transaction', 'TransactionTopup', 'TransactionTransfer', 'TransactionExchange',
    'ATMWithdrawRequest',
    'UserKYC',
    'Staff', 'Role', 'StaffRole', 'Permission', 'RolePermission',
    'SystemSetting', 'SettingsUpdate',
     'AuditLog',  'UserLimit',
    'CallCenter', 'Notification',
    'FraudReport',
    'FavoriteContact', 'FavoriteTransfer', 'FavoriteInternet',
    'APIConsumer', 'APIAccessLog', 'APIKeysUpdate',
    'LinkingBank',
    'ExchangeRate',
    'ExternalService', 'ExternalServiceLog'  # ✅ Added external services models
]
