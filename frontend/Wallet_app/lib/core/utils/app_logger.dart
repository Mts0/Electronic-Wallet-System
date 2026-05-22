import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static void d(Object? message) {
    instance.debug(message);
  }

  static void i(Object? message) {
    instance.info(message);
  }

  static void w(Object? message) {
    instance.warning(message);
  }

  static void e(
      Object? message, {
        Object? error,
        StackTrace? stackTrace,
      }) {
    instance.error(
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void debug(Object? message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  void info(Object? message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  void warning(Object? message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  void error(
      Object? message, {
        Object? error,
        StackTrace? stackTrace,
      }) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR_DETAILS] $error');
      }
      if (stackTrace != null) {
        debugPrint('$stackTrace');
      }
    }
  }
}