import 'package:y_wallet/features/transfer/data/datasources/transfer_datasource.dart';
import 'package:y_wallet/features/transfer/data/mappers/transfer_mapper.dart';
import 'package:y_wallet/features/transfer/data/models/execute_transfer_request_model.dart';
import 'package:y_wallet/features/transfer/data/models/transfer_precheck_request_model.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_entity.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_execution_result_entity.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_precheck_entity.dart';
import 'package:y_wallet/features/transfer/domain/repositories/transfer_repository.dart';

class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl(this._dataSource);

  final TransferDataSource _dataSource;

  @override
  Future<TransferPrecheckEntity> precheckTransfer({
    required String fromAccountId,
    required String toWalletNumber,
    required String currencyCode,
    required double amount,
  }) async {
    final request = TransferPrecheckRequestModel(
      fromAccountId: fromAccountId,
      toWalletNumber: toWalletNumber,
      currencyCode: currencyCode,
      amount: amount,
    );

    final response = await _dataSource.precheckTransfer(request);
    return response.toEntity();
  }

  @override
  Future<TransferExecutionResultEntity> executeTransfer({
    required TransferEntity transfer,
  }) async {
    final request = ExecuteTransferRequestModel(
      fromAccountId: transfer.fromAccountId,
      toWalletNumber: transfer.toWalletNumber,
      amount: transfer.amount,
      notes: transfer.notes,
    );

    final response = await _dataSource.executeTransfer(request);
    return response.toEntity();
  }
}
