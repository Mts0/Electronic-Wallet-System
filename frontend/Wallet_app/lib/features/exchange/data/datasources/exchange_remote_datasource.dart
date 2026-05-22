import 'package:dio/dio.dart';
import 'package:y_wallet/core/errors/app_exception.dart';
import 'package:y_wallet/features/exchange/data/config/exchange_api_paths.dart';
import 'package:y_wallet/features/exchange/data/datasources/exchange_datasource.dart';
import 'package:y_wallet/features/exchange/data/models/execute_exchange_request_model.dart';
import 'package:y_wallet/features/exchange/data/models/execute_exchange_response_model.dart';
import 'package:y_wallet/features/exchange/data/models/exchange_quote_response_model.dart';

class ExchangeRemoteDataSource implements ExchangeDataSource {
  ExchangeRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<ExchangeQuoteResponseModel> getPairRate({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    try {
      final response = await _dio.get(
        ExchangeApiPaths.pairRate,
        queryParameters: {
          'base_currency': baseCurrency.trim().toUpperCase(),
          'target_currency': targetCurrency.trim().toUpperCase(),
        },
      );

      final body = response.data;
      if (body is Map<String, dynamic>) {
        return ExchangeQuoteResponseModel.fromJson(body);
      }
      if (body is Map) {
        return ExchangeQuoteResponseModel.fromJson(Map<String, dynamic>.from(body));
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

  @override
  Future<ExecuteExchangeResponseModel> executeExchange(
    ExecuteExchangeRequestModel request,
  ) async {
    final json = await _post(ExchangeApiPaths.execute, request.toJson());
    return ExecuteExchangeResponseModel.fromJson(json);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(path, data: data);
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

    if (statusCode == 404) {
      return AppException.server(
        (message != null && message.trim().isNotEmpty)
            ? message
            : 'سعر الصرف غير متوفر لهذا الزوج',
      );
    }

    if (statusCode != null && statusCode >= 400 && statusCode < 600) {
      return AppException.server(
        (message != null && message.trim().isNotEmpty)
            ? message
            : 'تعذر تنفيذ عملية المصارفة حاليًا',
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
