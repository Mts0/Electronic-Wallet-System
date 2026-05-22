import 'package:y_wallet/features/wallet/data/models/wallet_account_model.dart';
import 'package:y_wallet/features/wallet/data/models/wallet_model.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_entity.dart';

extension WalletAccountModelMapper on WalletAccountModel {
  WalletAccountEntity toEntity() {
    return WalletAccountEntity(
      id: id,
      walletId: walletId,
      currencyId: currencyId,
      currencyCode: currencyCode,
      currencyName: currencyName,
      accountNumber: accountNumber,
      balance: balance,
      isPrimary: isPrimary,
      status: status,
    );
  }
}

extension WalletModelMapper on WalletModel {
  WalletEntity toEntity() {
    return WalletEntity(
      walletId: walletId,
      userId: userId,
      walletNumber: walletNumber,
      status: status,
      accounts: accounts.map((account) => account.toEntity()).toList(),
    );
  }
}
