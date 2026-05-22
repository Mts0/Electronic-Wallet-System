import 'package:y_wallet/features/auth/data/models/login_response_model.dart';
import 'package:y_wallet/features/auth/data/models/user_model.dart';
import 'package:y_wallet/features/auth/domain/entities/auth_session_entity.dart';
import 'package:y_wallet/features/auth/domain/entities/user_entity.dart';

extension UserModelMapper on UserModel {
  UserEntity toEntity() {
    return UserEntity(
      id: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      userType: userType,
      isVerified: isVerified,
      isActive: isActive,
      blockedReason: blockedReason,
      createdAt: createdAt,
    );
  }
}

extension LoginResponseModelMapper on LoginResponseModel {
  AuthSessionEntity toEntity() {
    return AuthSessionEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toEntity(),
    );
  }
}
