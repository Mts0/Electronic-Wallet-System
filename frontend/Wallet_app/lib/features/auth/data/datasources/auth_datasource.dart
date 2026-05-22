import 'package:y_wallet/features/auth/data/models/login_request_model.dart';
import 'package:y_wallet/features/auth/data/models/login_response_model.dart';
import 'package:y_wallet/features/auth/data/models/register_request_model.dart';
import 'package:y_wallet/features/auth/data/models/user_model.dart';

abstract class AuthDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);
  Future<UserModel> getMe();
  Future<UserModel> register(RegisterRequestModel request);
  Future<String> requestOtp({
    required String phoneNumber,
    required String verificationType,
  });
  Future<String> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required String verificationType,
  });
  Future<String> requestPasswordReset({
    required String phoneNumber,
  });
  Future<String> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  });
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<String> logout();
}
