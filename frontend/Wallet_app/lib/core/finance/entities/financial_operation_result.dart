enum FinancialOperationStatus {
  success,
  failed,
  pending,
}

class FinancialOperationResult {
  final FinancialOperationStatus status;
  final String? reference;
  final String? message;

  const FinancialOperationResult({
    required this.status,
    this.reference,
    this.message,
  });
}