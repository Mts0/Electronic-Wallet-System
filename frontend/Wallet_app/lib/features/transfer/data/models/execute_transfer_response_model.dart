class ExecuteTransferResponseModel {
  final String status;
  final String? transactionId;
  final String? reference;
  final String? message;

  const ExecuteTransferResponseModel({
    required this.status,
    this.transactionId,
    this.reference,
    this.message,
  });

  factory ExecuteTransferResponseModel.fromJson(Map<String, dynamic> json) {
    final transaction = (json['transaction'] as Map?) ?? const {};
    final transactionId = transaction['transaction_id']?.toString();
    final backendStatus = (transaction['status'] ?? '').toString().toUpperCase();

    return ExecuteTransferResponseModel(
      status: _normalizeStatus(backendStatus),
      transactionId: transactionId,
      reference: transactionId == null ? null : 'TX-$transactionId',
      message: (json['to_user_name'] ?? '').toString().trim().isEmpty
          ? null
          : 'تم التحويل إلى ${(json['to_user_name'] ?? '').toString().trim()}',
    );
  }

  static String _normalizeStatus(String value) {
    switch (value) {
      case 'PENDING':
        return 'pending';
      case 'FAILED':
        return 'failed';
      case 'COMPLETED':
      default:
        return 'success';
    }
  }
}
