import 'package:y_wallet/features/auth/domain/entities/auth_session_entity.dart';
import 'package:y_wallet/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<AuthSessionEntity> login({
    required String phoneNumber,
    required String password,
  });

  Future<UserEntity> getMe();

  Future<UserEntity> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String gender,
    required DateTime dateOfBirth,
    required String password,
  });

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
