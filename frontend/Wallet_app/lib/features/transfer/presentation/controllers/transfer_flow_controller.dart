import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_precheck_entity.dart';
import 'package:y_wallet/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:y_wallet/features/transfer/presentation/providers/transfer_providers.dart';
import 'package:y_wallet/features/transfer/presentation/utils/transfer_error_mapper.dart';

class TransferFlowState {
  final bool isChecking;
  final TransferPrecheckEntity? precheckResult;
  final String? inlineErrorMessage;
  final bool requiresLogin;

  const TransferFlowState({
    this.isChecking = false,
    this.precheckResult,
    this.inlineErrorMessage,
    this.requiresLogin = false,
  });

  bool get hasValidRecipient => precheckResult?.isValid == true;
  String? get recipientName => precheckResult?.recipientName;

  TransferFlowState copyWith({
    bool? isChecking,
    TransferPrecheckEntity? precheckResult,
    bool clearPrecheckResult = false,
    String? inlineErrorMessage,
    bool clearInlineError = false,
    bool? requiresLogin,
  }) {
    return TransferFlowState(
      isChecking: isChecking ?? this.isChecking,
      precheckResult: clearPrecheckResult
          ? null
          : (precheckResult ?? this.precheckResult),
      inlineErrorMessage: clearInlineError
          ? null
          : (inlineErrorMessage ?? this.inlineErrorMessage),
      requiresLogin: requiresLogin ?? this.requiresLogin,
    );
  }
}

final transferFlowProvider =
StateNotifierProvider<TransferFlowController, TransferFlowState>((ref) {
  final repository = ref.watch(transferRepositoryProvider);
  return TransferFlowController(repository);
});

class TransferFlowController extends StateNotifier<TransferFlowState> {
  TransferFlowController(this._repository) : super(const TransferFlowState());

  final TransferRepository _repository;

  void clearValidationState() {
    state = const TransferFlowState();
  }

  Future<bool> precheckTransfer({
    required String fromAccountId,
    required String toWalletNumber,
    required String currencyCode,
    required double amount,
  }) async {
    state = const TransferFlowState(isChecking: true);

    try {
      final result = await _repository.precheckTransfer(
        fromAccountId: fromAccountId,
        toWalletNumber: toWalletNumber,
        currencyCode: currencyCode,
        amount: amount,
      );

      if (!result.isValid) {
        state = TransferFlowState(
          isChecking: false,
          precheckResult: result,
          inlineErrorMessage:
          result.message?.trim().isNotEmpty == true
              ? result.message
              : 'تعذر التحقق من بيانات المستلم',
          requiresLogin: false,
        );
        return false;
      }

      state = TransferFlowState(
        isChecking: false,
        precheckResult: result,
        inlineErrorMessage: null,
        requiresLogin: false,
      );
      return true;
    } catch (error) {
      final mapped = TransferErrorMapper.map(error);

      state = TransferFlowState(
        isChecking: false,
        inlineErrorMessage: mapped.message,
        requiresLogin: mapped.shouldLogout,
      );

      return false;
    }
  }
}