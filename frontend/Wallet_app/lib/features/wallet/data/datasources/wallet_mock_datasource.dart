import 'dart:async';
import 'package:y_wallet/features/wallet/data/datasources/wallet_datasource.dart';
import 'package:y_wallet/features/wallet/data/models/wallet_account_model.dart';
import 'package:y_wallet/features/wallet/data/models/wallet_model.dart';

class WalletMockDataSource implements WalletDataSource {
  @override
  Future<WalletModel> getWallet() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const WalletModel(
      walletId: 1,
      userId: 1,
      walletNumber: '7700002418',
      status: 'ACTIVE',
      accounts: [
        WalletAccountModel(
          id: 1,
          walletId: 1,
          currencyId: 1,
          currencyCode: 'YER',
          currencyName: 'الريال اليمني',
          accountNumber: '7700002418',
          balance: 125000.75,
          isPrimary: true,
          status: 'ACTIVE',
        ),
        WalletAccountModel(
          id: 2,
          walletId: 1,
          currencyId: 3,
          currencyCode: 'SAR',
          currencyName: 'الريال السعودي',
          accountNumber: '7700002418',
          balance: 2480.50,
          isPrimary: false,
          status: 'ACTIVE',
        ),
        WalletAccountModel(
          id: 3,
          walletId: 1,
          currencyId: 2,
          currencyCode: 'USD',
          currencyName: 'الدولار الأمريكي',
          accountNumber: '7700002418',
          balance: 820.25,
          isPrimary: false,
          status: 'ACTIVE',
        ),
      ],
    );
  }
}
