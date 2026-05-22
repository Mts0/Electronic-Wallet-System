import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/features/transfer/domain/entities/transfer_entity.dart';

class TransferFormState {
  final int? fromAccountId;
  final int? currencyId;
  final String fromAccountName;
  final String fromCurrencyCode;
  final String fromAccountNumber;
  final String toWalletNumber;
  final String amount;
  final String notes;

  const TransferFormState({
    this.fromAccountId,
    this.currencyId,
    this.fromAccountName = '',
    this.fromCurrencyCode = '',
    this.fromAccountNumber = '',
    this.toWalletNumber = '',
    this.amount = '',
    this.notes = '',
  });

  TransferFormState copyWith({
    int? fromAccountId,
    bool clearFromAccountId = false,
    int? currencyId,
    bool clearCurrencyId = false,
    String? fromAccountName,
    String? fromCurrencyCode,
    String? fromAccountNumber,
    String? toWalletNumber,
    String? amount,
    String? notes,
  }) {
    return TransferFormState(
      fromAccountId:
      clearFromAccountId ? null : (fromAccountId ?? this.fromAccountId),
      currencyId: clearCurrencyId ? null : (currencyId ?? this.currencyId),
      fromAccountName: fromAccountName ?? this.fromAccountName,
      fromCurrencyCode: fromCurrencyCode ?? this.fromCurrencyCode,
      fromAccountNumber: fromAccountNumber ?? this.fromAccountNumber,
      toWalletNumber: toWalletNumber ?? this.toWalletNumber,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  bool get isReadyForConfirm {
    return fromAccountId != null &&
        currencyId != null &&
        toWalletNumber.trim().isNotEmpty &&
        amount.trim().isNotEmpty;
  }

  TransferEntity toEntity() {
    return TransferEntity(
      fromAccountId: fromAccountId!,
      currencyId: currencyId!,
      fromAccountName: fromAccountName,
      fromCurrencyCode: fromCurrencyCode,
      fromAccountNumber: fromAccountNumber,
      toWalletNumber: toWalletNumber.trim(),
      amount: double.parse(amount.trim()),
      notes: notes.trim(),
    );
  }
}

final transferFormProvider =
StateNotifierProvider<TransferFormController, TransferFormState>((ref) {
  return TransferFormController();
});

class TransferFormController extends StateNotifier<TransferFormState> {
  TransferFormController() : super(const TransferFormState());

  void setSourceAccount({
    required int accountId,
    required int currencyId,
    required String accountName,
    required String currencyCode,
    required String accountNumber,
  }) {
    state = state.copyWith(
      fromAccountId: accountId,
      currencyId: currencyId,
      fromAccountName: accountName,
      fromCurrencyCode: currencyCode,
      fromAccountNumber: accountNumber,
    );
  }

  void setWalletNumber(String value) {
    state = state.copyWith(toWalletNumber: value);
  }

  void setAmount(String value) {
    state = state.copyWith(amount: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void reset() {
    state = const TransferFormState();
  }
}