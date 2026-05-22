import 'package:y_wallet/features/auth/domain/entities/user_entity.dart';

class AuthSessionEntity {
  final String accessToken;
  final String? refreshToken;
  final UserEntity user;

  const AuthSessionEntity({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });
}