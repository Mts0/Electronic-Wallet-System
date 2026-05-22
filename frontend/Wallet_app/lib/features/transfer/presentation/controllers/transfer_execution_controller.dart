import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/finance/entities/financial_operation_result.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_execution_result_entity.dart';
import 'package:y_wallet/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:y_wallet/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:y_wallet/features/transfer/presentation/providers/transfer_providers.dart';
import 'package:y_wallet/features/transfer/presentation/utils/transfer_error_mapper.dart';

class TransferExecutionState {
  final FinancialOperationResult? result;
  final bool requiresLogin;
  final String? localErrorMessage;

  const TransferExecutionState({
    this.result,
    this.requiresLogin = false,
    this.localErrorMessage,
  });

  TransferExecutionState copyWith({
    FinancialOperationResult? result,
    bool clearResult = false,
    bool? requiresLogin,
    String? localErrorMessage,
    bool clearLocalError = false,
  }) {
    return TransferExecutionState(
      result: clearResult ? null : (result ?? this.result),
      requiresLogin: requiresLogin ?? this.requiresLogin,
      localErrorMessage: clearLocalError
          ? null
          : (localErrorMessage ?? this.localErrorMessage),
    );
  }
}

final transferExecutionProvider = StateNotifierProvider<
    TransferExecutionController, TransferExecutionState>((ref) {
  final repository = ref.watch(transferRepositoryProvider);
  return TransferExecutionController(ref, repository);
});

class TransferExecutionController extends StateNotifier<TransferExecutionState> {
  TransferExecutionController(this._ref, this._repository)
      : super(const TransferExecutionState());

  final Ref _ref;
  final TransferRepository _repository;

  void reset() {
    state = const TransferExecutionState();
  }

  Future<void> executeVerifiedTransfer() async {
    final form = _ref.read(transferFormProvider);

    if (!form.isReadyForConfirm) {
      state = const TransferExecutionState(
        localErrorMessage: 'بيانات التحويل غير مكتملة',
      );
      return;
    }

    try {
      final transfer = form.toEntity();

      final result = await _repository.executeTransfer(
        transfer: transfer,
      );

      state = TransferExecutionState(
        result: FinancialOperationResult(
          status: _mapStatus(result.status),
          reference: result.reference,
          message: result.message,
        ),
      );
    } catch (error) {
      final mapped = TransferErrorMapper.map(error);

      if (mapped.shouldLogout) {
        state = TransferExecutionState(
          requiresLogin: true,
          localErrorMessage: mapped.message,
        );
        return;
      }

      state = TransferExecutionState(
        result: FinancialOperationResult(
          status: FinancialOperationStatus.failed,
          message: mapped.message,
        ),
      );
    }
  }

  FinancialOperationStatus _mapStatus(TransferExecutionResultStatus status) {
    switch (status) {
      case TransferExecutionResultStatus.pending:
        return FinancialOperationStatus.pending;
      case TransferExecutionResultStatus.failed:
        return FinancialOperationStatus.failed;
      case TransferExecutionResultStatus.success:
        return FinancialOperationStatus.success;
    }
  }
}