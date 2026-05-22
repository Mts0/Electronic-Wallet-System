import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/finance/entities/financial_operation_result.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/bill_payment/presentation/controllers/mobile_topup_controller.dart';

class MobileTopupExecutionState {
  final FinancialOperationResult? result;
  final bool requiresLogin;
  final String? localErrorMessage;

  const MobileTopupExecutionState({
    this.result,
    this.requiresLogin = false,
    this.localErrorMessage,
  });

  MobileTopupExecutionState copyWith({
    FinancialOperationResult? result,
    bool clearResult = false,
    bool? requiresLogin,
    String? localErrorMessage,
    bool clearLocalError = false,
  }) {
    return MobileTopupExecutionState(
      result: clearResult ? null : (result ?? this.result),
      requiresLogin: requiresLogin ?? this.requiresLogin,
      localErrorMessage: clearLocalError ? null : (localErrorMessage ?? this.localErrorMessage),
    );
  }
}

final mobileTopupExecutionProvider = StateNotifierProvider<
    MobileTopupExecutionController, MobileTopupExecutionState>((ref) {
  final dio = ref.watch(dioProvider);
  return MobileTopupExecutionController(ref, dio);
});

class MobileTopupExecutionController extends StateNotifier<MobileTopupExecutionState> {
  MobileTopupExecutionController(this._ref, this._dio)
      : super(const MobileTopupExecutionState());

  final Ref _ref;
  final Dio _dio;

  void reset() {
    state = const MobileTopupExecutionState();
  }

  Future<void> executeVerifiedTopup() async {
    final form = _ref.read(mobileTopupFormProvider);

    if (!form.isReadyForConfirm) {
      state = const MobileTopupExecutionState(
        localErrorMessage: 'بيانات شحن الهاتف غير مكتملة',
      );
      return;
    }

    final topup = form.toEntity();

    try {
      final response = await _dio.post(
        '/transactions/mobile-topup',
        data: {
          'amount': topup.amount,
          'phone_number': topup.phoneNumber,
          if (topup.notes.trim().isNotEmpty) 'notes': topup.notes,
        },
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      final transaction = body['transaction'] is Map<String, dynamic>
          ? body['transaction'] as Map<String, dynamic>
          : Map<String, dynamic>.from((body['transaction'] ?? const {}) as Map);
      final statusRaw = (transaction['status'] ?? '').toString().toUpperCase();

      state = MobileTopupExecutionState(
        result: FinancialOperationResult(
          status: _mapStatus(statusRaw),
          reference: (body['transaction_ref'] ?? '').toString(),
          message: (body['status_details'] ?? body['message'] ?? 'تم تنفيذ عملية الشحن').toString(),
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        state = MobileTopupExecutionState(
          requiresLogin: true,
          localErrorMessage: 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',
        );
        return;
      }

      state = MobileTopupExecutionState(
        result: FinancialOperationResult(
          status: FinancialOperationStatus.failed,
          message: _extractMessage(e),
        ),
      );
    } catch (e) {
      state = MobileTopupExecutionState(
        result: FinancialOperationResult(
          status: FinancialOperationStatus.failed,
          message: e.toString(),
        ),
      );
    }
  }

  FinancialOperationStatus _mapStatus(String statusRaw) {
    switch (statusRaw) {
      case 'PENDING':
        return FinancialOperationStatus.pending;
      case 'FAILED':
        return FinancialOperationStatus.failed;
      default:
        return FinancialOperationStatus.success;
    }
  }

  String _extractMessage(DioException e) {
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
    return 'تعذر تنفيذ عملية الشحن';
  }
}
