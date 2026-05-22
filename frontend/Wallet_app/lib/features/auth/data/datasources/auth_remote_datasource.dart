import 'package:dio/dio.dart';
import 'package:y_wallet/features/auth/data/datasources/auth_datasource.dart';
import 'package:y_wallet/features/auth/data/models/login_request_model.dart';
import 'package:y_wallet/features/auth/data/models/login_response_model.dart';
import 'package:y_wallet/features/auth/data/models/register_request_model.dart';
import 'package:y_wallet/features/auth/data/models/user_model.dart';

class AuthRemoteDataSource implements AuthDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: request.toJson(),
      );
      return LoginResponseModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(_extractMessage(
        e,
        unauthorizedFallback: 'بيانات الدخول غير صحيحة',
        defaultMessage: 'حدث خطأ أثناء تسجيل الدخول',
      ));
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(_extractMessage(
        e,
        unauthorizedFallback: 'انتهت الجلسة',
        defaultMessage: 'تعذر تحميل بيانات المستخدم',
      ));
    }
  }

  @override
  Future<UserModel> register(RegisterRequestModel request) async {
    try {
      final response = await _dio.post('/auth/register', data: request.toJson());
      return UserModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(_extractMessage(
        e,
        defaultMessage: 'تعذر إنشاء الحساب',
      ));
    }
  }

  @override
  Future<String> requestOtp({
    required String phoneNumber,
    required String verificationType,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/request-otp',
        data: {
          'phone_number': phoneNumber,
          'verification_type': verificationType,
        },
      );
      return _extractSuccessMessage(response.data, 'تم إرسال رمز التحقق');
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, defaultMessage: 'تعذر إرسال رمز التحقق'));
    }
  }

  @override
  Future<String> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required String verificationType,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'phone_number': phoneNumber,
          'otp_code': otpCode,
          'verification_type': verificationType,
        },
      );
      return _extractSuccessMessage(response.data, 'تم التحقق من الرمز بنجاح');
    } on DioException catch (e) {
      throw Exception(_extractMessage(
        e,
        defaultMessage: 'رمز التحقق غير صحيح أو منتهي الصلاحية',
      ));
    }
  }

  @override
  Future<String> requestPasswordReset({
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/password/forgot',
        data: {'phone_number': phoneNumber},
      );
      return _extractSuccessMessage(response.data, 'تم إرسال رمز استعادة كلمة المرور');
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, defaultMessage: 'تعذر إرسال رمز الاستعادة'));
    }
  }

  @override
  Future<String> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/password/reset',
        data: {
          'phone_number': phoneNumber,
          'otp_code': otpCode,
          'new_password': newPassword,
        },
      );
      return _extractSuccessMessage(response.data, 'تم تعيين كلمة المرور الجديدة بنجاح');
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, defaultMessage: 'تعذر تعيين كلمة المرور الجديدة'));
    }
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return _extractSuccessMessage(response.data, 'تم تغيير كلمة المرور بنجاح');
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, defaultMessage: 'تعذر تغيير كلمة المرور'));
    }
  }

  @override
  Future<String> logout() async {
    try {
      final response = await _dio.post('/auth/logout');
      return _extractSuccessMessage(response.data, 'تم تسجيل الخروج بنجاح');
    } on DioException catch (e) {
      throw Exception(_extractMessage(
        e,
        unauthorizedFallback: 'انتهت الجلسة',
        defaultMessage: 'تعذر تسجيل الخروج',
      ));
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('استجابة غير صالحة من الخادم');
  }

  String _extractSuccessMessage(dynamic data, String fallback) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  String _extractMessage(
    DioException e, {
    String? unauthorizedFallback,
    required String defaultMessage,
  }) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'تعذر الاتصال بالخادم';
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final detail = map['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
      final message = map['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (e.response?.statusCode == 401 && unauthorizedFallback != null) {
      return unauthorizedFallback;
    }

    return defaultMessage;
  }
}
