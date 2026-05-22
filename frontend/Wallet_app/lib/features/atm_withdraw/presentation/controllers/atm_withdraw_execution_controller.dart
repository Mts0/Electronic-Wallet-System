import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/atm_withdraw/presentation/controllers/atm_withdraw_controller.dart';
import 'package:y_wallet/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';

class AtmWithdrawReceipt {
  final int requestId;
  final String bankName;
  final String? bankCode;
  final String code;
  final String pinCode;
  final String amount;
  final String currencyCode;
  final String status;
  final DateTime? expiresAt;
  final String reference;
  final String message;

  const AtmWithdrawReceipt({
    required this.requestId,
    required this.bankName,
    required this.bankCode,
    required this.code,
    required this.pinCode,
    required this.amount,
    required this.currencyCode,
    required this.status,
    required this.expiresAt,
    required this.reference,
    required this.message,
  });
}

class AtmWithdrawExecutionState {
  final AtmWithdrawReceipt? receipt;
  final bool requiresLogin;
  final String? localErrorMessage;

  const AtmWithdrawExecutionState({
    this.receipt,
    this.requiresLogin = false,
    this.localErrorMessage,
  });
}

final atmWithdrawExecutionProvider = StateNotifierProvider<
    AtmWithdrawExecutionController, AtmWithdrawExecutionState>((ref) {
  final dio = ref.watch(dioProvider);
  return AtmWithdrawExecutionController(ref, dio);
});

class AtmWithdrawExecutionController
    extends StateNotifier<AtmWithdrawExecutionState> {
  AtmWithdrawExecutionController(this._ref, this._dio)
      : super(const AtmWithdrawExecutionState());

  final Ref _ref;
  final Dio _dio;

  void reset() {
    state = const AtmWithdrawExecutionState();
  }

  Future<void> executeVerifiedWithdraw() async {
    final form = _ref.read(atmWithdrawFormProvider);
    if (!form.isReadyForConfirm) {
      state = const AtmWithdrawExecutionState(
        localErrorMessage: 'بيانات السحب بدون بطاقة غير مكتملة',
      );
      return;
    }

    try {
      final response = await _dio.post(
        '/transactions/atm-withdraw',
        data: {
          'account_id': form.accountId,
          'amount': form.amount.trim(),
          'bank_id': form.bankId,
          if (form.note.trim().isNotEmpty) 'message': form.note.trim(),
        },
      );

      final raw = response.data;
      final body = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);

      final receipt = AtmWithdrawReceipt(
        requestId: ((body['request_id'] ?? 0) as num).toInt(),
        bankName: (body['bank_name'] ?? form.bankName).toString(),
        bankCode: body['bank_code']?.toString(),
        code: (body['code'] ?? '').toString(),
        pinCode: (body['pin_code'] ?? '').toString(),
        amount: (body['amount'] ?? form.amount).toString(),
        currencyCode: form.currencyCode,
        status: (body['status'] ?? 'PENDING').toString(),
        expiresAt: body['expires_at'] == null
            ? null
            : DateTime.tryParse(body['expires_at'].toString()),
        reference: (body['transaction_ref'] ?? '').toString(),
        message: 'تم إنشاء طلب السحب بدون بطاقة بنجاح',
      );

      await _ref.read(walletControllerProvider.notifier).loadWallet();
      await _ref.read(transactionControllerProvider.notifier).loadTransactions();

      state = AtmWithdrawExecutionState(receipt: receipt);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        state = AtmWithdrawExecutionState(
          requiresLogin: true,
          localErrorMessage: 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',
        );
        return;
      }

      state = AtmWithdrawExecutionState(
        localErrorMessage: extractAtmWithdrawErrorMessage(
          e,
          'تعذر إنشاء طلب السحب بدون بطاقة',
        ),
      );
    } catch (e) {
      state = AtmWithdrawExecutionState(
        localErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
