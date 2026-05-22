import 'package:y_wallet/features/transfer/data/models/execute_transfer_request_model.dart';
import 'package:y_wallet/features/transfer/data/models/execute_transfer_response_model.dart';
import 'package:y_wallet/features/transfer/data/models/transfer_precheck_request_model.dart';
import 'package:y_wallet/features/transfer/data/models/transfer_precheck_response_model.dart';

abstract class TransferDataSource {
  Future<TransferPrecheckResponseModel> precheckTransfer(
      TransferPrecheckRequestModel request,
      );

  Future<ExecuteTransferResponseModel> executeTransfer(
      ExecuteTransferRequestModel request,
      );
}