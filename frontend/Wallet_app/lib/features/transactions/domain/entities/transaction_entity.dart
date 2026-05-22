enum TransactionStatus {
  success,
  pending,
  failed,
}

enum TransactionDirection {
  incoming,
  outgoing,
}

class TransactionEntity {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String currencyCode;
  final DateTime createdAt;
  final TransactionStatus status;
  final TransactionDirection direction;
  final String reference;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.createdAt,
    required this.status,
    required this.direction,
    required this.reference,
  });
}