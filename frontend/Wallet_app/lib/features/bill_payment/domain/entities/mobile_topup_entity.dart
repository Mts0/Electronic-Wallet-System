class MobileTopupEntity {
  final int fromAccountId;
  final int currencyId;
  final String fromAccountName;
  final String fromCurrencyCode;
  final String fromAccountNumber;
  final String phoneNumber;
  final String operatorName;
  final double amount;
  final String notes;

  const MobileTopupEntity({
    required this.fromAccountId,
    required this.currencyId,
    required this.fromAccountName,
    required this.fromCurrencyCode,
    required this.fromAccountNumber,
    required this.phoneNumber,
    required this.operatorName,
    required this.amount,
    required this.notes,
  });
}