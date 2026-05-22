import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';

class WalletEntity {
  final int walletId;
  final int userId;
  final String walletNumber;
  final String status;
  final List<WalletAccountEntity> accounts;

  const WalletEntity({
    required this.walletId,
    required this.userId,
    required this.walletNumber,
    required this.status,
    required this.accounts,
  });

  WalletEntity copyWith({
    int? walletId,
    int? userId,
    String? walletNumber,
    String? status,
    List<WalletAccountEntity>? accounts,
  }) {
    return WalletEntity(
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      walletNumber: walletNumber ?? this.walletNumber,
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
    );
  }
}
