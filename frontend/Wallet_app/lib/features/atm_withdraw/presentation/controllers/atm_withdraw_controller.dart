import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/providers/core_providers.dart';

class BankOption {
  final int bankId;
  final String name;
  final String? code;
  final bool isActive;

  const BankOption({
    required this.bankId,
    required this.name,
    required this.code,
    required this.isActive,
  });

  factory BankOption.fromJson(Map<String, dynamic> json) {
    return BankOption(
      bankId: ((json['bank_id'] ?? 0) as num).toInt(),
      name: (json['name'] ?? '').toString(),
      code: json['code']?.toString(),
      isActive: json['is_active'] != false,
    );
  }
}

class AtmWithdrawFormState {
  final int? accountId;
  final int? currencyId;
  final String accountName;
  final String accountNumber;
  final String currencyCode;
  final int? bankId;
  final String bankName;
  final String amount;
  final String note;

  const AtmWithdrawFormState({
    this.accountId,
    this.currencyId,
    this.accountName = '',
    this.accountNumber = '',
    this.currencyCode = '',
    this.bankId,
    this.bankName = '',
    this.amount = '',
    this.note = '',
  });

  bool get isReadyForConfirm {
    return accountId != null &&
        currencyId != null &&
        bankId != null &&
        amount.trim().isNotEmpty &&
        currencyCode.trim().isNotEmpty;
  }

  AtmWithdrawFormState copyWith({
    int? accountId,
    bool clearAccountId = false,
    int? currencyId,
    bool clearCurrencyId = false,
    String? accountName,
    String? accountNumber,
    String? currencyCode,
    int? bankId,
    bool clearBankId = false,
    String? bankName,
    String? amount,
    String? note,
  }) {
    return AtmWithdrawFormState(
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      currencyId: clearCurrencyId ? null : (currencyId ?? this.currencyId),
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      bankId: clearBankId ? null : (bankId ?? this.bankId),
      bankName: bankName ?? this.bankName,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }
}

class AtmWithdrawFormController extends StateNotifier<AtmWithdrawFormState> {
  AtmWithdrawFormController() : super(const AtmWithdrawFormState());

  void setSourceAccount({
    required int accountId,
    required int currencyId,
    required String accountName,
    required String accountNumber,
    required String currencyCode,
  }) {
    state = state.copyWith(
      accountId: accountId,
      currencyId: currencyId,
      accountName: accountName,
      accountNumber: accountNumber,
      currencyCode: currencyCode,
    );
  }

  void setBank({
    required int bankId,
    required String bankName,
  }) {
    state = state.copyWith(
      bankId: bankId,
      bankName: bankName,
    );
  }

  void setAmount(String value) {
    state = state.copyWith(amount: value);
  }

  void setNote(String value) {
    state = state.copyWith(note: value);
  }

  void reset() {
    state = const AtmWithdrawFormState();
  }
}

final atmWithdrawFormProvider = StateNotifierProvider<
    AtmWithdrawFormController, AtmWithdrawFormState>((ref) {
  return AtmWithdrawFormController();
});

final atmBanksProvider = FutureProvider<List<BankOption>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/banking/banks');
  final data = response.data;

  Iterable rawItems = const [];
  if (data is List) {
    rawItems = data;
  } else if (data is Map<String, dynamic>) {
    rawItems = (data['items'] as List?) ??
        (data['results'] as List?) ??
        (data['data'] as List?) ??
        const [];
  } else if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    rawItems = (map['items'] as List?) ??
        (map['results'] as List?) ??
        (map['data'] as List?) ??
        const [];
  }

  return rawItems
      .whereType<Map>()
      .map((item) => BankOption.fromJson(Map<String, dynamic>.from(item)))
      .where((item) => item.isActive)
      .toList();
});

String extractAtmWithdrawErrorMessage(DioException e, String fallback) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return 'تعذر الاتصال بالخادم';
  }

  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final detail = map['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) return message;
  }
  if (data is String && data.trim().isNotEmpty) return data;
  return fallback;
}
