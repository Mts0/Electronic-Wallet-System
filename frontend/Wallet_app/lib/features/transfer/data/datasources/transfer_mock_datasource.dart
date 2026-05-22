import 'dart:async';

import 'package:y_wallet/core/errors/app_exception.dart';
import 'package:y_wallet/features/transfer/data/datasources/transfer_datasource.dart';
import 'package:y_wallet/features/transfer/data/models/execute_transfer_request_model.dart';
import 'package:y_wallet/features/transfer/data/models/execute_transfer_response_model.dart';
import 'package:y_wallet/features/transfer/data/models/transfer_precheck_request_model.dart';
import 'package:y_wallet/features/transfer/data/models/transfer_precheck_response_model.dart';

class TransferMockDataSource implements TransferDataSource {
  @override
  Future<TransferPrecheckResponseModel> precheckTransfer(
      TransferPrecheckRequestModel request,
      ) async {
    await Future.delayed(const Duration(milliseconds: 550));

    final wallet = request.toWalletNumber.trim();

    if (wallet.isEmpty || wallet.length < 4) {
      return const TransferPrecheckResponseModel(
        isValid: false,
        errorCode: 'invalid_wallet_number',
        message: 'رقم المحفظة غير صحيح',
      );
    }

    if (wallet.endsWith('401')) {
      throw AppException.sessionExpired();
    }

    if (wallet.endsWith('505')) {
      throw AppException.network();
    }

    if (wallet.endsWith('909')) {
      throw AppException.security();
    }

    if (wallet.endsWith('000')) {
      return const TransferPrecheckResponseModel(
        isValid: false,
        errorCode: 'recipient_not_found',
        message: 'المستلم غير موجود',
      );
    }

    if (wallet.endsWith('999')) {
      return const TransferPrecheckResponseModel(
        isValid: false,
        errorCode: 'recipient_blocked',
        message: 'هذا المستلم غير متاح للاستقبال حاليًا',
      );
    }

    if (request.amount <= 0) {
      return const TransferPrecheckResponseModel(
        isValid: false,
        errorCode: 'invalid_amount',
        message: 'المبلغ غير صحيح',
      );
    }

    return TransferPrecheckResponseModel(
      isValid: true,
      recipientName: 'مستلم ${wallet.substring(wallet.length - 4)}',
      errorCode: null,
      message: 'التحقق ناجح',
    );
  }

  @override
  Future<ExecuteTransferResponseModel> executeTransfer(
      ExecuteTransferRequestModel request,
      ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final wallet = request.toWalletNumber.trim();
    final amount = request.amount;

    if (wallet.endsWith('401')) {
      throw AppException.sessionExpired();
    }

    if (wallet.endsWith('505')) {
      throw AppException.network();
    }

    if (wallet.endsWith('909')) {
      throw AppException.security();
    }

    if (wallet.endsWith('404')) {
      return const ExecuteTransferResponseModel(
        status: 'failed',
        message: 'تعذر تنفيذ العملية، المستلم غير متاح',
      );
    }

    if (wallet.endsWith('777')) {
      return const ExecuteTransferResponseModel(
        status: 'failed',
        message: 'تعذر تنفيذ العملية حاليًا',
      );
    }

    if (amount >= 10000 && amount < 20000) {
      return ExecuteTransferResponseModel(
        status: 'pending',
        transactionId: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        reference: 'PND-${DateTime.now().millisecondsSinceEpoch}',
        message: 'العملية قيد المعالجة',
      );
    }

    return ExecuteTransferResponseModel(
      status: 'success',
      transactionId: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      reference: 'TRF-${DateTime.now().millisecondsSinceEpoch}',
      message: 'تم تنفيذ العملية بنجاح',
    );
  }
}