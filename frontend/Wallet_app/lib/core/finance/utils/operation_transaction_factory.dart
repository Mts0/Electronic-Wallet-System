import 'package:y_wallet/core/finance/entities/financial_operation_result.dart';
import 'package:y_wallet/core/finance/utils/financial_operation_status_mapper.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';

class OperationTransactionFactory {
  static TransactionEntity buildOutgoing({
    required String title,
    required String description,
    required double amount,
    required String currencyCode,
    required FinancialOperationResult result,
    String? idPrefix,
  }) {
    final now = DateTime.now();

    return TransactionEntity(
      id: '${idPrefix ?? 'op'}_${now.microsecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      currencyCode: currencyCode,
      createdAt: now,
      status:
      FinancialOperationStatusMapper.toTransactionStatus(result.status),
      direction: TransactionDirection.outgoing,
      reference: result.reference ?? _defaultReference(result.status, now),
    );
  }

  static String _defaultReference(
      FinancialOperationStatus status,
      DateTime now,
      ) {
    switch (status) {
      case FinancialOperationStatus.pending:
        return 'PND-${now.millisecondsSinceEpoch}';
      case FinancialOperationStatus.failed:
        return 'FLD-${now.millisecondsSinceEpoch}';
      case FinancialOperationStatus.success:
        return 'SUC-${now.millisecondsSinceEpoch}';
    }
  }
}