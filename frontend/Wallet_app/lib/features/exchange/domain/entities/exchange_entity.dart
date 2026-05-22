class ExchangeEntity {
  final int fromAccountId;
  final int toAccountId;
  final int fromCurrencyId;
  final int toCurrencyId;
  final String fromAccountName;
  final String toAccountName;
  final String fromCurrencyCode;
  final String toCurrencyCode;
  final String fromAccountNumber;
  final String toAccountNumber;
  final double fromAmount;
  final String notes;

  const ExchangeEntity({
    required this.fromAccountId,
    required this.toAccountId,
    required this.fromCurrencyId,
    required this.toCurrencyId,
    required this.fromAccountName,
    required this.toAccountName,
    required this.fromCurrencyCode,
    required this.toCurrencyCode,
    required this.fromAccountNumber,
    required this.toAccountNumber,
    required this.fromAmount,
    required this.notes,
  });
}
