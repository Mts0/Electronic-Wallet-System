import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/finance/entities/financial_operation_result.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_execution_result_entity.dart';
import 'package:y_wallet/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:y_wallet/features/exchange/presentation/controllers/exchange_controller.dart';
import 'package:y_wallet/features/exchange/presentation/providers/exchange_providers.dart';
import 'package:y_wallet/features/exchange/presentation/utils/exchange_error_mapper.dart';

class ExchangeExecutionState {
  final FinancialOperationResult? result;
  final bool requiresLogin;
  final String? localErrorMessage;

  const ExchangeExecutionState({
    this.result,
    this.requiresLogin = false,
    this.localErrorMessage,
  });

  ExchangeExecutionState copyWith({
    FinancialOperationResult? result,
    bool clearResult = false,
    bool? requiresLogin,
    String? localErrorMessage,
    bool clearLocalError = false,
  }) {
    return ExchangeExecutionState(
      result: clearResult ? null : (result ?? this.result),
      requiresLogin: requiresLogin ?? this.requiresLogin,
      localErrorMessage:
          clearLocalError ? null : (localErrorMessage ?? this.localErrorMessage),
    );
  }
}

final exchangeExecutionProvider = StateNotifierProvider<
    ExchangeExecutionController, ExchangeExecutionState>((ref) {
  final repository = ref.watch(exchangeRepositoryProvider);
  return ExchangeExecutionController(ref, repository);
});

class ExchangeExecutionController extends StateNotifier<ExchangeExecutionState> {
  ExchangeExecutionController(this._ref, this._repository)
      : super(const ExchangeExecutionState());

  final Ref _ref;
  final ExchangeRepository _repository;

  void reset() {
    state = const ExchangeExecutionState();
  }

  Future<void> executeVerifiedExchange() async {
    final form = _ref.read(exchangeFormProvider);

    if (!form.isReadyForConfirm) {
      state = const ExchangeExecutionState(
        localErrorMessage: 'بيانات المصارفة غير مكتملة',
      );
      return;
    }

    try {
      final exchange = form.toEntity();
      final result = await _repository.executeExchange(exchange: exchange);

      String? message = result.message;
      if ((message ?? '').trim().isEmpty && result.toAmount != null) {
        message = 'تمت المصارفة واستلام ${result.toAmount!.toStringAsFixed(2)} ${exchange.toCurrencyCode}';
      }

      state = ExchangeExecutionState(
        result: FinancialOperationResult(
          status: _mapStatus(result.status),
          reference: result.reference,
          message: message,
        ),
      );
    } catch (error) {
      final mapped = ExchangeErrorMapper.map(error);

      if (mapped.shouldLogout) {
        state = ExchangeExecutionState(
          requiresLogin: true,
          localErrorMessage: mapped.message,
        );
        return;
      }

      state = ExchangeExecutionState(
        result: FinancialOperationResult(
          status: FinancialOperationStatus.failed,
          message: mapped.message,
        ),
      );
    }
  }

  FinancialOperationStatus _mapStatus(ExchangeExecutionResultStatus status) {
    switch (status) {
      case ExchangeExecutionResultStatus.pending:
        return FinancialOperationStatus.pending;
      case ExchangeExecutionResultStatus.failed:
        return FinancialOperationStatus.failed;
      case ExchangeExecutionResultStatus.success:
        return FinancialOperationStatus.success;
    }
  }
}
