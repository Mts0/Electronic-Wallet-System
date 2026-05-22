import 'package:y_wallet/features/wallet/data/models/wallet_account_model.dart';

class WalletModel {
  final int walletId;
  final int userId;
  final String walletNumber;
  final String status;
  final List<WalletAccountModel> accounts;

  const WalletModel({
    required this.walletId,
    required this.userId,
    required this.walletNumber,
    required this.status,
    required this.accounts,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final rawAccounts = (json['accounts'] as List?) ?? const [];
    final walletNumber = (json['wallet_number'] ?? '').toString();

    return WalletModel(
      walletId: (json['wallet_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      walletNumber: walletNumber,
      status: (json['status'] ?? '').toString(),
      accounts: rawAccounts
          .asMap()
          .entries
          .map(
            (entry) => WalletAccountModel.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
              walletNumber: walletNumber,
              isPrimary: entry.key == 0,
            ),
          )
          .toList(),
    );
  }
}
