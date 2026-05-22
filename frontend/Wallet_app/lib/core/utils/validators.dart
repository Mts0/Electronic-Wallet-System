class AppValidators {
  static const int phoneMinLength = 9;
  static const int passwordMinLength = 6;
  static const int otpLength = 6;

  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }

    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(phone);
    if (!isDigitsOnly) {
      return 'رقم الهاتف يجب أن يكون أرقام فقط';
    }

    if (phone.length < phoneMinLength) {
      return 'رقم الهاتف قصير جدًا';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }

    if (password.length < passwordMinLength) {
      return 'كلمة المرور يجب أن تكون 6 أحرف/أرقام على الأقل';
    }

    return null;
  }

  static String? validateConfirmPassword(
    String? value, {
    required String originalPassword,
  }) {
    final confirmPassword = value?.trim() ?? '';

    final baseValidation = validatePassword(confirmPassword);
    if (baseValidation != null) {
      return baseValidation;
    }

    if (confirmPassword != originalPassword.trim()) {
      return 'كلمتا المرور غير متطابقتين';
    }

    return null;
  }

  static String? validateOtp(String? value) {
    final otp = value?.trim() ?? '';

    if (otp.isEmpty) {
      return 'رمز OTP مطلوب';
    }

    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(otp);
    if (!isDigitsOnly) {
      return 'رمز OTP يجب أن يكون أرقام فقط';
    }

    if (otp.length != otpLength) {
      return 'رمز OTP يجب أن يكون 6 أرقام';
    }

    return null;
  }

  static String? validatePin(String? value) {
    final pin = value?.trim() ?? '';

    if (pin.isEmpty) {
      return 'رمز PIN مطلوب';
    }

    final isDigitsOnly = RegExp(r'^\d+$').hasMatch(pin);
    if (!isDigitsOnly) {
      return 'رمز PIN يجب أن يكون أرقام فقط';
    }

    if (pin.length != 4) {
      return 'رمز PIN يجب أن يكون 4 أرقام';
    }

    return null;
  }
}
