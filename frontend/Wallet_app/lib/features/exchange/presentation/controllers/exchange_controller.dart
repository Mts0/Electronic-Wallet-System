import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_entity.dart';

class ExchangeFormState {
  final int? fromAccountId;
  final int? toAccountId;
  final int? fromCurrencyId;
  final int? toCurrencyId;
  final String fromAccountName;
  final String toAccountName;
  final String fromCurrencyCode;
  final String toCurrencyCode;
  final String fromAccountNumber;
  final String toAccountNumber;
  final String amount;
  final String notes;

  const ExchangeFormState({
    this.fromAccountId,
    this.toAccountId,
    this.fromCurrencyId,
    this.toCurrencyId,
    this.fromAccountName = '',
    this.toAccountName = '',
    this.fromCurrencyCode = '',
    this.toCurrencyCode = '',
    this.fromAccountNumber = '',
    this.toAccountNumber = '',
    this.amount = '',
    this.notes = '',
  });

  ExchangeFormState copyWith({
    int? fromAccountId,
    bool clearFromAccountId = false,
    int? toAccountId,
    bool clearToAccountId = false,
    int? fromCurrencyId,
    bool clearFromCurrencyId = false,
    int? toCurrencyId,
    bool clearToCurrencyId = false,
    String? fromAccountName,
    String? toAccountName,
    String? fromCurrencyCode,
    String? toCurrencyCode,
    String? fromAccountNumber,
    String? toAccountNumber,
    String? amount,
    String? notes,
  }) {
    return ExchangeFormState(
      fromAccountId: clearFromAccountId ? null : (fromAccountId ?? this.fromAccountId),
      toAccountId: clearToAccountId ? null : (toAccountId ?? this.toAccountId),
      fromCurrencyId: clearFromCurrencyId ? null : (fromCurrencyId ?? this.fromCurrencyId),
      toCurrencyId: clearToCurrencyId ? null : (toCurrencyId ?? this.toCurrencyId),
      fromAccountName: fromAccountName ?? this.fromAccountName,
      toAccountName: toAccountName ?? this.toAccountName,
      fromCurrencyCode: fromCurrencyCode ?? this.fromCurrencyCode,
      toCurrencyCode: toCurrencyCode ?? this.toCurrencyCode,
      fromAccountNumber: fromAccountNumber ?? this.fromAccountNumber,
      toAccountNumber: toAccountNumber ?? this.toAccountNumber,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  bool get isReadyForConfirm {
    return fromAccountId != null &&
        toAccountId != null &&
        fromCurrencyId != null &&
        toCurrencyId != null &&
        fromCurrencyCode.trim().isNotEmpty &&
        toCurrencyCode.trim().isNotEmpty &&
        amount.trim().isNotEmpty;
  }

  ExchangeEntity toEntity() {
    return ExchangeEntity(
      fromAccountId: fromAccountId!,
      toAccountId: toAccountId!,
      fromCurrencyId: fromCurrencyId!,
      toCurrencyId: toCurrencyId!,
      fromAccountName: fromAccountName,
      toAccountName: toAccountName,
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCode: toCurrencyCode,
      fromAccountNumber: fromAccountNumber,
      toAccountNumber: toAccountNumber,
      fromAmount: double.parse(amount.trim()),
      notes: notes.trim(),
    );
  }
}

final exchangeFormProvider =
    StateNotifierProvider<ExchangeFormController, ExchangeFormState>((ref) {
  return ExchangeFormController();
});

class ExchangeFormController extends StateNotifier<ExchangeFormState> {
  ExchangeFormController() : super(const ExchangeFormState());

  void setFromAccount({
    required int accountId,
    required int currencyId,
    required String accountName,
    required String currencyCode,
    required String accountNumber,
  }) {
    state = state.copyWith(
      fromAccountId: accountId,
      fromCurrencyId: currencyId,
      fromAccountName: accountName,
      fromCurrencyCode: currencyCode,
      fromAccountNumber: accountNumber,
    );
  }

  void clearToAccount() {
    state = state.copyWith(
      clearToAccountId: true,
      clearToCurrencyId: true,
      toAccountName: '',
      toCurrencyCode: '',
      toAccountNumber: '',
    );
  }

  void setToAccount({
    required int accountId,
    required int currencyId,
    required String accountName,
    required String currencyCode,
    required String accountNumber,
  }) {
    state = state.copyWith(
      toAccountId: accountId,
      toCurrencyId: currencyId,
      toAccountName: accountName,
      toCurrencyCode: currencyCode,
      toAccountNumber: accountNumber,
    );
  }

  void setAmount(String value) {
    state = state.copyWith(amount: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void reset() {
    state = const ExchangeFormState();
  }
}
