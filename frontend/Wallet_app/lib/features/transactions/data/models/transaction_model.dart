class TransactionModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String currencyCode;
  final String createdAtIso;
  final String status;
  final String direction;
  final String reference;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.createdAtIso,
    required this.status,
    required this.direction,
    required this.reference,
  });

  factory TransactionModel.fromBackendJson(
    Map<String, dynamic> json, {
    required Map<int, String> currenciesMap,
  }) {
    final transactionId = ((json['transaction_id'] ?? 0) as num).toInt();
    final currencyId = ((json['currency_id'] ?? 0) as num).toInt();
    final type = (json['type'] ?? '').toString();
    final notes = (json['notes'] ?? '').toString();

    return TransactionModel(
      id: transactionId.toString(),
      title: _titleFromType(type),
      description: notes.trim().isNotEmpty ? notes : _defaultDescription(type),
      amount: double.tryParse((json['amount'] ?? '0').toString()) ?? 0,
      currencyCode: currenciesMap[currencyId] ?? 'CUR-$currencyId',
      createdAtIso: (json['created_at'] ?? '').toString(),
      status: _statusFromBackend((json['status'] ?? '').toString()),
      direction: _directionFromType(type),
      reference: 'TX-$transactionId',
    );
  }

  static String _statusFromBackend(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return 'pending';
      case 'FAILED':
        return 'failed';
      case 'COMPLETED':
      default:
        return 'success';
    }
  }

  static String _directionFromType(String type) {
    switch (type.toUpperCase()) {
      case 'CASH_IN':
      case 'INITIAL_FUNDING':
        return 'incoming';
      default:
        return 'outgoing';
    }
  }

  static String _titleFromType(String type) {
    switch (type.toUpperCase()) {
      case 'TRANSFER':
        return 'تحويل مالي';
      case 'MOBILE_TOPUP':
        return 'شحن هاتف';
      case 'ATM_WITHDRAW':
        return 'سحب نقدي';
      case 'EXCHANGE':
        return 'تحويل عملة';
      case 'CASH_IN':
        return 'إيداع نقدي';
      case 'CASH_DEPOSIT':
        return 'إيداع';
      case 'INITIAL_FUNDING':
        return 'تمويل أولي';
      default:
        return 'عملية مالية';
    }
  }

  static String _defaultDescription(String type) {
    switch (type.toUpperCase()) {
      case 'TRANSFER':
        return 'عملية تحويل من المحفظة';
      case 'MOBILE_TOPUP':
        return 'شحن رصيد هاتف';
      case 'ATM_WITHDRAW':
        return 'طلب سحب من الصراف';
      case 'EXCHANGE':
        return 'عملية صرف عملات';
      case 'CASH_IN':
      case 'CASH_DEPOSIT':
        return 'عملية إيداع';
      default:
        return 'تفاصيل غير متوفرة';
    }
  }
}
