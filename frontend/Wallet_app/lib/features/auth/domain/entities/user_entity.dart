class UserEntity {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String userType;
  final bool isVerified;
  final bool isActive;
  final String? blockedReason;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.userType,
    required this.isVerified,
    required this.isActive,
    this.blockedReason,
    this.createdAt,
  });
}
