import 'package:y_wallet/features/transactions/data/models/transaction_model.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';

extension TransactionModelMapper on TransactionModel {
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      title: title,
      description: description,
      amount: amount,
      currencyCode: currencyCode,
      createdAt: DateTime.parse(createdAtIso),
      status: _mapStatus(status),
      direction: _mapDirection(direction),
      reference: reference,
    );
  }
}

TransactionStatus _mapStatus(String value) {
  switch (value) {
    case 'pending':
      return TransactionStatus.pending;
    case 'failed':
      return TransactionStatus.failed;
    case 'success':
    default:
      return TransactionStatus.success;
  }
}

TransactionDirection _mapDirection(String value) {
  switch (value) {
    case 'incoming':
      return TransactionDirection.incoming;
    case 'outgoing':
    default:
      return TransactionDirection.outgoing;
  }
}