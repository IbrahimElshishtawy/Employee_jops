/// Base and specialized application exceptions (Data/Infrastructure layer)
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'AppException: $message (statusCode: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({String message = 'No internet connection', dynamic details})
      : super(message, details: details);
}

class TimeoutException extends AppException {
  const TimeoutException({String message = 'Connection timeout', dynamic details})
      : super(message, details: details);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({String message = 'Unauthorized session. Please login.', dynamic details})
      : super(message, statusCode: 401, details: details);
}

class ForbiddenException extends AppException {
  const ForbiddenException({String message = 'Access forbidden. Insufficient permissions.', dynamic details})
      : super(message, statusCode: 403, details: details);
}

class NotFoundException extends AppException {
  const NotFoundException({String message = 'Requested resource not found', dynamic details})
      : super(message, statusCode: 404, details: details);
}

class ValidationException extends AppException {
  const ValidationException({String message = 'Invalid data provided', dynamic details})
      : super(message, statusCode: 422, details: details);
}

class ServerException extends AppException {
  const ServerException({String message = 'Internal server error occurred', int? statusCode, dynamic details})
      : super(message, statusCode: statusCode ?? 500, details: details);
}

class UnknownException extends AppException {
  const UnknownException({String message = 'An unexpected error occurred', dynamic details})
      : super(message, details: details);
}
