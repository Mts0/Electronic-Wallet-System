import 'package:y_wallet/features/auth/data/datasources/auth_datasource.dart';
import 'package:y_wallet/features/auth/data/mappers/auth_mapper.dart';
import 'package:y_wallet/features/auth/data/models/login_request_model.dart';
import 'package:y_wallet/features/auth/data/models/register_request_model.dart';
import 'package:y_wallet/features/auth/domain/entities/auth_session_entity.dart';
import 'package:y_wallet/features/auth/domain/entities/user_entity.dart';
import 'package:y_wallet/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<AuthSessionEntity> login({
    required String phoneNumber,
    required String password,
  }) async {
    final request = LoginRequestModel(
      phoneNumber: phoneNumber,
      password: password,
    );

    final response = await dataSource.login(request);
    return response.toEntity();
  }

  @override
  Future<UserEntity> getMe() async {
    final user = await dataSource.getMe();
    return user.toEntity();
  }

  @override
  Future<UserEntity> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String gender,
    required DateTime dateOfBirth,
    required String password,
  }) async {
    final request = RegisterRequestModel(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      gender: gender,
      dateOfBirth: dateOfBirth.toIso8601String().split('T').first,
      password: password,
    );

    final user = await dataSource.register(request);
    return user.toEntity();
  }

  @override
  Future<String> requestOtp({
    required String phoneNumber,
    required String verificationType,
  }) {
    return dataSource.requestOtp(
      phoneNumber: phoneNumber,
      verificationType: verificationType,
    );
  }

  @override
  Future<String> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required String verificationType,
  }) {
    return dataSource.verifyOtp(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
      verificationType: verificationType,
    );
  }

  @override
  Future<String> requestPasswordReset({required String phoneNumber}) {
    return dataSource.requestPasswordReset(phoneNumber: phoneNumber);
  }

  @override
  Future<String> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) {
    return dataSource.resetPassword(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
      newPassword: newPassword,
    );
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return dataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<String> logout() {
    return dataSource.logout();
  }
}
