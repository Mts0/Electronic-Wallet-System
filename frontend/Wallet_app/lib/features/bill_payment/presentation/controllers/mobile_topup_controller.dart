import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/features/bill_payment/domain/entities/mobile_topup_entity.dart';

class MobileTopupFormState {
  final int? fromAccountId;
  final int? currencyId;
  final String fromAccountName;
  final String fromCurrencyCode;
  final String fromAccountNumber;
  final String phoneNumber;
  final String operatorName;
  final String amount;
  final String notes;

  const MobileTopupFormState({
    this.fromAccountId,
    this.currencyId,
    this.fromAccountName = '',
    this.fromCurrencyCode = '',
    this.fromAccountNumber = '',
    this.phoneNumber = '',
    this.operatorName = '',
    this.amount = '',
    this.notes = '',
  });

  bool get isReadyForConfirm {
    return fromAccountId != null &&
        currencyId != null &&
        fromAccountName.trim().isNotEmpty &&
        fromCurrencyCode.trim().isNotEmpty &&
        fromAccountNumber.trim().isNotEmpty &&
        phoneNumber.trim().isNotEmpty &&
        operatorName.trim().isNotEmpty &&
        amount.trim().isNotEmpty;
  }

  MobileTopupFormState copyWith({
    int? fromAccountId,
    int? currencyId,
    String? fromAccountName,
    String? fromCurrencyCode,
    String? fromAccountNumber,
    String? phoneNumber,
    String? operatorName,
    String? amount,
    String? notes,
    bool clearSourceAccount = false,
  }) {
    return MobileTopupFormState(
      fromAccountId:
      clearSourceAccount ? null : (fromAccountId ?? this.fromAccountId),
      currencyId: clearSourceAccount ? null : (currencyId ?? this.currencyId),
      fromAccountName:
      clearSourceAccount ? '' : (fromAccountName ?? this.fromAccountName),
      fromCurrencyCode:
      clearSourceAccount ? '' : (fromCurrencyCode ?? this.fromCurrencyCode),
      fromAccountNumber:
      clearSourceAccount ? '' : (fromAccountNumber ?? this.fromAccountNumber),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      operatorName: operatorName ?? this.operatorName,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  MobileTopupEntity toEntity() {
    return MobileTopupEntity(
      fromAccountId: fromAccountId!,
      currencyId: currencyId!,
      fromAccountName: fromAccountName,
      fromCurrencyCode: fromCurrencyCode,
      fromAccountNumber: fromAccountNumber,
      phoneNumber: phoneNumber,
      operatorName: operatorName,
      amount: double.tryParse(amount.trim()) ?? 0,
      notes: notes,
    );
  }
}

final mobileTopupFormProvider =
StateNotifierProvider<MobileTopupController, MobileTopupFormState>((ref) {
  return MobileTopupController();
});

class MobileTopupController extends StateNotifier<MobileTopupFormState> {
  MobileTopupController() : super(const MobileTopupFormState());

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

  void setPhoneNumber({
    required String value,
    required String operatorName,
  }) {
    state = state.copyWith(
      phoneNumber: value,
      operatorName: operatorName,
    );
  }

  void setAmount(String value) {
    state = state.copyWith(amount: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void reset() {
    state = const MobileTopupFormState();
  }
}