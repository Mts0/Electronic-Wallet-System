import 'package:y_wallet/features/transfer/domain/entities/transfer_entity.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_execution_result_entity.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_precheck_entity.dart';

abstract class TransferRepository {
  Future<TransferPrecheckEntity> precheckTransfer({
    required String fromAccountId,
    required String toWalletNumber,
    required String currencyCode,
    required double amount,
  });

  Future<TransferExecutionResultEntity> executeTransfer({
    required TransferEntity transfer,
  });
}