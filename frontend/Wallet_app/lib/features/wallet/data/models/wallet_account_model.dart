class WalletAccountModel {
  final int id;
  final int walletId;
  final int currencyId;
  final String currencyCode;
  final String currencyName;
  final String accountNumber;
  final double balance;
  final bool isPrimary;
  final String status;

  const WalletAccountModel({
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

  factory WalletAccountModel.fromJson(
    Map<String, dynamic> json, {
    required String walletNumber,
    required bool isPrimary,
  }) {
    final currency = (json['currency'] as Map?) ?? const {};
    return WalletAccountModel(
      id: (json['account_id'] as num).toInt(),
      walletId: (json['wallet_id'] as num).toInt(),
      currencyId: ((currency['currency_id'] ?? 0) as num).toInt(),
      currencyCode: (currency['symbol'] ?? '').toString(),
      currencyName: (currency['name'] ?? '').toString(),
      accountNumber: walletNumber,
      balance: double.tryParse((json['balance'] ?? '0').toString()) ?? 0,
      isPrimary: isPrimary,
      status: (json['status'] ?? '').toString(),
    );
  }
}
