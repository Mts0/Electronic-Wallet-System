class RegisterRequestModel {
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String gender;
  final String dateOfBirth;
  final String password;

  const RegisterRequestModel({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.gender,
    required this.dateOfBirth,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      if (email != null && email!.trim().isNotEmpty) 'email': email,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'password': password,
    };
  }
}
