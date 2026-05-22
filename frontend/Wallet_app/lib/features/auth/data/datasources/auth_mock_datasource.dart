import 'package:y_wallet/features/auth/data/datasources/auth_datasource.dart';
import 'package:y_wallet/features/auth/data/models/login_request_model.dart';
import 'package:y_wallet/features/auth/data/models/login_response_model.dart';
import 'package:y_wallet/features/auth/data/models/register_request_model.dart';
import 'package:y_wallet/features/auth/data/models/user_model.dart';

class AuthMockDataSource implements AuthDataSource {
  Never _unsupported() {
    throw UnsupportedError('تم تعطيل mock auth. استخدم الباك اند الحقيقي.');
  }

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async => _unsupported();

  @override
  Future<UserModel> getMe() async => _unsupported();

  @override
  Future<UserModel> register(RegisterRequestModel request) async => _unsupported();

  @override
  Future<String> requestOtp({
    required String phoneNumber,
    required String verificationType,
  }) async => _unsupported();

  @override
  Future<String> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required String verificationType,
  }) async => _unsupported();

  @override
  Future<String> requestPasswordReset({required String phoneNumber}) async => _unsupported();

  @override
  Future<String> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async => _unsupported();

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => _unsupported();

  @override
  Future<String> logout() async => _unsupported();
}
