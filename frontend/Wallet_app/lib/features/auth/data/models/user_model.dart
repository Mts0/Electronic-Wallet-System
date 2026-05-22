class UserModel {
  final int userId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String userType;
  final bool isVerified;
  final bool isActive;
  final String? blockedReason;
  final DateTime? createdAt;

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.userType,
    required this.isVerified,
    required this.isActive,
    this.blockedReason,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: ((json['user_id'] ?? 0) as num).toInt(),
      fullName: (json['full_name'] ?? '').toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      email: json['email']?.toString(),
      userType: (json['user_type'] ?? '').toString(),
      isVerified: json['is_verified'] == true,
      isActive: json['is_active'] == true,
      blockedReason: json['blocked_reason']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
