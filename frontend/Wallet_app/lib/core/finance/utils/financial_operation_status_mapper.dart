import 'package:y_wallet/core/finance/entities/financial_operation_result.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';

class FinancialOperationStatusMapper {
  static TransactionStatus toTransactionStatus(
      FinancialOperationStatus status,
      ) {
    switch (status) {
      case FinancialOperationStatus.pending:
        return TransactionStatus.pending;
      case FinancialOperationStatus.failed:
        return TransactionStatus.failed;
      case FinancialOperationStatus.success:
        return TransactionStatus.success;
    }
  }
}