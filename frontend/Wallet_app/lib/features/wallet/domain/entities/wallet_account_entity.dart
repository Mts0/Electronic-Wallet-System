class WalletAccountEntity {
  final int id;
  final int walletId;
  final int currencyId;
  final String currencyCode;
  final String currencyName;
  final String accountNumber;
  final double balance;
  final bool isPrimary;
  final String status;

  const WalletAccountEntity({
    required this.id,
    required this.walletId,
    required this.currencyId,
    required this.currencyCode,
    required this.currencyName,
    required this.accountNumber,
    required this.balance,
    required this.isPrimary,
    required this.status,
  });

  WalletAccountEntity copyWith({
    int? id,
    int? walletId,
    int? currencyId,
    String? currencyCode,
    String? currencyName,
    String? accountNumber,
    double? balance,
    bool? isPrimary,
    String? status,
  }) {
    return WalletAccountEntity(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      currencyId: currencyId ?? this.currencyId,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyName: currencyName ?? this.currencyName,
      accountNumber: accountNumber ?? this.accountNumber,
      balance: balance ?? this.balance,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
    );
  }
}
