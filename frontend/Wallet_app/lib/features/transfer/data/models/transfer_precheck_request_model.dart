class TransferPrecheckRequestModel {
  final String fromAccountId;
  final String toWalletNumber;
  final String currencyCode;
  final double amount;

  const TransferPrecheckRequestModel({
    required this.fromAccountId,
    required this.toWalletNumber,
    required this.currencyCode,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'from_account_id': fromAccountId,
      'to_wallet_number': toWalletNumber,
      'currency_code': currencyCode,
      'amount': amount,
    };
  }
}