import 'package:dio/dio.dart';
import 'package:y_wallet/core/errors/app_exception.dart';
import 'package:y_wallet/features/transfer/data/config/transfer_api_paths.dart';
import 'package:y_wallet/features/transfer/data/datasources/transfer_datasource.dart';
import 'package:y_wallet/features/transfer/data/models/execute_transfer_request_model.dart';
import 'package:y_wallet/features/transfer/data/models/execute_transfer_response_model.dart';
import 'package:y_wallet/features/transfer/data/models/transfer_precheck_request_model.dart';
import 'package:y_wallet/features/transfer/data/models/transfer_precheck_response_model.dart';

class TransferRemoteDataSource implements TransferDataSource {
  TransferRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<TransferPrecheckResponseModel> precheckTransfer(
    TransferPrecheckRequestModel request,
  ) async {
    final wallet = request.toWalletNumber.trim();
    if (wallet.isEmpty || wallet.length < 4 || request.amount <= 0) {
      return const TransferPrecheckResponseModel(
        isValid: false,
        errorCode: 'invalid_input',
        message: 'بيانات التحويل غير صحيحة',
      );
    }

    return const TransferPrecheckResponseModel(
      isValid: true,
      recipientName: null,
      errorCode: null,
      message: null,
    );
  }

  @override
  Future<ExecuteTransferResponseModel> executeTransfer(
    ExecuteTransferRequestModel request,
  ) async {
    final json = await _post(
      TransferApiPaths.execute,
      request.toJson(),
    );

    return ExecuteTransferResponseModel.fromJson(json);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
      );

      final body = response.data;

      if (body is Map<String, dynamic>) {
        return body;
      }

      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }

      throw AppException.server('استجابة غير صالحة من الخادم');
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on AppException {
      rethrow;
    } catch (_) {
      throw AppException.unknown();
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return AppException.network();
    }

    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e.response?.data);

    if (statusCode == 401) {
      return AppException.sessionExpired(
        (message != null && message.trim().isNotEmpty)
            ? message
            : 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',
      );
    }

    if (statusCode == 403) {
      return AppException.security(
        (message != null && message.trim().isNotEmpty)
            ? message
            : 'تم إيقاف العملية لأسباب أمنية',
      );
    }

    if (statusCode != null && statusCode >= 400 && statusCode < 600) {
      return AppException.server(
        (message != null && message.trim().isNotEmpty)
            ? message
            : 'تعذر تنفيذ العملية حاليًا',
      );
    }

    return AppException.unknown(
      (message != null && message.trim().isNotEmpty)
          ? message
          : 'حدث خطأ غير متوقع',
    );
  }

  String? _extractMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directMessage = data['message'];
      if (directMessage is String && directMessage.trim().isNotEmpty) {
        return directMessage;
      }

      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }

      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }

      final description = data['description'];
      if (description is String && description.trim().isNotEmpty) {
        return description;
      }

      return null;
    }

    if (data is Map) {
      return _extractMessage(Map<String, dynamic>.from(data));
    }

    return null;
  }
}
