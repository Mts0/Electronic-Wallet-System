class ExecuteExchangeResponseModel {
  final String status;
  final String? transactionId;
  final String? reference;
  final String? message;
  final double? toAmount;
  final double? exchangeRate;

  const ExecuteExchangeResponseModel({
    required this.status,
    this.transactionId,
    this.reference,
    this.message,
    this.toAmount,
    this.exchangeRate,
  });

  factory ExecuteExchangeResponseModel.fromJson(Map<String, dynamic> json) {
    final transaction = (json['transaction'] as Map?) ?? const {};
    final transactionId = transaction['transaction_id']?.toString();
    final backendStatus = (transaction['status'] ?? '').toString().toUpperCase();
    final toAmount = double.tryParse((json['to_amount'] ?? '').toString());
    final exchangeRate = double.tryParse((json['exchange_rate'] ?? '').toString());

    String? message;
    if (toAmount != null && exchangeRate != null) {
      message = 'تم تنفيذ المصارفة بسعر $exchangeRate واستلام ${toAmount.toStringAsFixed(2)}';
    }

    return ExecuteExchangeResponseModel(
      status: _normalizeStatus(backendStatus),
      transactionId: transactionId,
      reference: transactionId == null ? null : 'EXC-$transactionId',
      message: message,
      toAmount: toAmount,
      exchangeRate: exchangeRate,
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
