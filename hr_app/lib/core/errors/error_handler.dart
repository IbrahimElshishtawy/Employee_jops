import 'app_exception.dart';
import 'failure.dart';

/// Maps low-level exceptions to user-safe domain failures
class ErrorHandler {
  ErrorHandler._();

  static Failure mapExceptionToFailure(dynamic error) {
    if (error is AppException) {
      switch (error) {
        case NetworkException():
          return const NetworkFailure();
        case TimeoutException():
          return const NetworkFailure(message: 'Connection timed out. Please retry.');
        case UnauthorizedException(message: final msg):
          return AuthFailure(message: msg);
        case ForbiddenException(message: final msg):
          return PermissionFailure(message: msg);
        case NotFoundException(message: final msg):
          return NotFoundFailure(message: msg);
        case ValidationException(message: final msg):
          return ValidationFailure(message: msg);
        case ServerException(message: final msg):
          return ServerFailure(message: msg);
        case UnknownException(message: final msg):
          return UnknownFailure(message: msg);
      }
    }

    if (error is Failure) {
      return error;
    }

    return UnknownFailure(message: error?.toString() ?? 'An unexpected error occurred.');
  }

  /// Converts any status code into an AppException
  static AppException fromStatusCode(int statusCode, {String? message, dynamic details}) {
    switch (statusCode) {
      case 400:
      case 422:
        return ValidationException(message: message ?? 'Validation failed', details: details);
      case 401:
        return UnauthorizedException(message: message ?? 'Session expired', details: details);
      case 403:
        return ForbiddenException(message: message ?? 'Access denied', details: details);
      case 404:
        return NotFoundException(message: message ?? 'Resource not found', details: details);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(message: message ?? 'Server unavailable', statusCode: statusCode, details: details);
      default:
        return ServerException(message: message ?? 'Request error', statusCode: statusCode, details: details);
    }
  }
}
