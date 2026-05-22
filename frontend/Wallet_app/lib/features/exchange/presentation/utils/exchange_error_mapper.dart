import 'package:y_wallet/core/errors/app_exception.dart';

class ExchangeMappedError {
  final String message;
  final bool shouldLogout;

  const ExchangeMappedError({
    required this.message,
    this.shouldLogout = false,
  });
}

class ExchangeErrorMapper {
  static ExchangeMappedError map(Object error) {
    if (error is AppException) {
      switch (error.type) {
        case AppExceptionType.sessionExpired:
          return ExchangeMappedError(
            message: error.message,
            shouldLogout: true,
          );
        case AppExceptionType.network:
        case AppExceptionType.security:
        case AppExceptionType.server:
        case AppExceptionType.unknown:
          return ExchangeMappedError(message: error.message);
      }
    }

    return const ExchangeMappedError(
      message: 'حدث خطأ غير متوقع، حاول مرة أخرى',
    );
  }
}
