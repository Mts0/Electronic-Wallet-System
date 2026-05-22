import 'package:y_wallet/features/transfer/data/models/execute_transfer_response_model.dart';
import 'package:y_wallet/features/transfer/data/models/transfer_precheck_response_model.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_execution_result_entity.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_precheck_entity.dart';

extension TransferPrecheckMapper on TransferPrecheckResponseModel {
  TransferPrecheckEntity toEntity() {
    return TransferPrecheckEntity(
      isValid: isValid,
      recipientName: recipientName,
      errorCode: errorCode,
      message: message,
    );
  }
}

extension ExecuteTransferMapper on ExecuteTransferResponseModel {
  TransferExecutionResultEntity toEntity() {
    return TransferExecutionResultEntity(
      status: _mapStatus(status),
      transactionId: transactionId,
      reference: reference,
      message: message,
    );
  }
}

TransferExecutionResultStatus _mapStatus(String value) {
  switch (value) {
    case 'pending':
      return TransferExecutionResultStatus.pending;
    case 'failed':
      return TransferExecutionResultStatus.failed;
    case 'success':
    default:
      return TransferExecutionResultStatus.success;
  }
}