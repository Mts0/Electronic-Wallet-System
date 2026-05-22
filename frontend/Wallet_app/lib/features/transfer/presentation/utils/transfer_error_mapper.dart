import 'package:y_wallet/core/errors/app_exception.dart';

class TransferMappedError {
  final String message;
  final bool shouldLogout;

  const TransferMappedError({
    required this.message,
    this.shouldLogout = false,
  });
}

class TransferErrorMapper {
  static TransferMappedError map(Object error) {
    if (error is AppException) {
      switch (error.type) {
        case AppExceptionType.sessionExpired:
          return TransferMappedError(
            message: error.message,
            shouldLogout: true,
          );
        case AppExceptionType.network:
        case AppExceptionType.security:
        case AppExceptionType.server:
        case AppExceptionType.unknown:
          return TransferMappedError(
            message: error.message,
          );
      }
    }

    return const TransferMappedError(
      message: 'حدث خطأ غير متوقع، حاول مرة أخرى',
    );
  }
}