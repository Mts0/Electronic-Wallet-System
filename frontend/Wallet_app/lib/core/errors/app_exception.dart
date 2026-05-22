enum AppExceptionType {
  network,
  sessionExpired,
  security,
  server,
  unknown,
}

class AppException implements Exception {
  final AppExceptionType type;
  final String message;
  final String? code;

  const AppException({
    required this.type,
    required this.message,
    this.code,
  });

  factory AppException.network([
    String message = 'تعذر الاتصال بالشبكة، حاول مرة أخرى',
  ]) {
    return AppException(
      type: AppExceptionType.network,
      message: message,
      code: 'network_error',
    );
  }

  factory AppException.sessionExpired([
    String message = 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',
  ]) {
    return AppException(
      type: AppExceptionType.sessionExpired,
      message: message,
      code: 'session_expired',
    );
  }

  factory AppException.security([
    String message = 'تم إيقاف العملية لأسباب أمنية',
  ]) {
    return AppException(
      type: AppExceptionType.security,
      message: message,
      code: 'security_blocked',
    );
  }

  factory AppException.server([
    String message = 'تعذر تنفيذ العملية حاليًا',
  ]) {
    return AppException(
      type: AppExceptionType.server,
      message: message,
      code: 'server_error',
    );
  }

  factory AppException.unknown([
    String message = 'حدث خطأ غير متوقع',
  ]) {
    return AppException(
      type: AppExceptionType.unknown,
      message: message,
      code: 'unknown_error',
    );
  }

  @override
  String toString() {
    return 'AppException(type: $type, code: $code, message: $message)';
  }
}