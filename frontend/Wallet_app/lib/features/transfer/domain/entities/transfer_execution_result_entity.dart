enum TransferExecutionResultStatus {
  success,
  failed,
  pending,
}

class TransferExecutionResultEntity {
  final TransferExecutionResultStatus status;
  final String? transactionId;
  final String? reference;
  final String? message;

  const TransferExecutionResultEntity({
    required this.status,
    this.transactionId,
    this.reference,
    this.message,
  });
}