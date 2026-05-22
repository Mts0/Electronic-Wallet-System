class TransferEntity {
  final int fromAccountId;
  final int currencyId;
  final String fromAccountName;
  final String fromCurrencyCode;
  final String fromAccountNumber;
  final String toWalletNumber;
  final double amount;
  final String notes;

  const TransferEntity({
    required this.fromAccountId,
    required this.currencyId,
    required this.fromAccountName,
    required this.fromCurrencyCode,
    required this.fromAccountNumber,
    required this.toWalletNumber,
    required this.amount,
    required this.notes,
  });
}