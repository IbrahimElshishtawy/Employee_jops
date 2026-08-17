/// Base class for all data-layer exceptions.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error occurred', super.code]);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection unavailable', super.code]);
}

class LocationException extends AppException {
  const LocationException([super.message = 'Location error occurred', super.code]);
}

class BiometricException extends AppException {
  const BiometricException([super.message = 'Biometric authentication failed', super.code]);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred', super.code]);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication error', super.code]);
}
