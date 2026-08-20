import 'package:flutter/foundation.dart';

/// Sanitized logger that avoids printing auth tokens or sensitive data
class LoggingInterceptor {
  static void logRequest(String method, String url, {dynamic body, Map<String, String>? headers}) {
    if (!kDebugMode) return;
    final sanitizedHeaders = Map<String, String>.from(headers ?? {});
    if (sanitizedHeaders.containsKey('Authorization')) {
      sanitizedHeaders['Authorization'] = 'Bearer [REDACTED]';
    }
    debugPrint('🌐 [HTTP REQ] $method $url');
  }

  static void logResponse(String method, String url, int statusCode, {String? bodyPreview}) {
    if (!kDebugMode) return;
    debugPrint('✅ [HTTP RES] $statusCode $method $url');
  }

  static void logError(String method, String url, dynamic error) {
    if (!kDebugMode) return;
    debugPrint('❌ [HTTP ERR] $method $url -> $error');
  }
}
