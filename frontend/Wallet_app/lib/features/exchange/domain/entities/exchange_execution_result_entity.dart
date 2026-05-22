enum ExchangeExecutionResultStatus {
  success,
  failed,
  pending,
}

class ExchangeExecutionResultEntity {
  final ExchangeExecutionResultStatus status;
  final String? transactionId;
  final String? reference;
  final String? message;
  final double? toAmount;
  final double? exchangeRate;

  const ExchangeExecutionResultEntity({
    required this.status,
    this.transactionId,
    this.reference,
    this.message,
    this.toAmount,
    this.exchangeRate,
  });
}
