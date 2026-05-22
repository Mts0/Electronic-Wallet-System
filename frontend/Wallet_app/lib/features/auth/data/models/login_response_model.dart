import 'package:y_wallet/features/auth/data/models/user_model.dart';

class LoginResponseModel {
  final String accessToken;
  final String? refreshToken;
  final UserModel user;

  const LoginResponseModel({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}