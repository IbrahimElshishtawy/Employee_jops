import 'package:flutter/foundation.dart';

/// SecureLogger ensures sensitive employee telemetry (tokens, passwords, National IDs,
/// precise coordinates) are sanitized and never leaked to production console or logs.
class SecureLogger {
  SecureLogger._();

  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void warn(String tag, String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [$tag] $message');
    }
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [$tag] $message ${error != null ? 'Error: $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }

  /// Sanitizes sensitive string (masks middle characters)
  static String maskSensitive(String? value, {int visiblePrefix = 2, int visibleSuffix = 2}) {
    if (value == null || value.isEmpty) return '***';
    if (value.length <= visiblePrefix + visibleSuffix) {
      return '*' * value.length;
    }
    final prefix = value.substring(0, visiblePrefix);
    final suffix = value.substring(value.length - visibleSuffix);
    final masked = '*' * (value.length - visiblePrefix - visibleSuffix);
    return '$prefix$masked$suffix';
  }

  /// Sanitizes email address (e.g. j***e@company.com)
  static String maskEmail(String? email) {
    if (email == null || !email.contains('@')) return '***@***.***';
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    final maskedName = name.length > 2
        ? '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}'
        : '${name[0]}*';
    return '$maskedName@$domain';
  }
}
