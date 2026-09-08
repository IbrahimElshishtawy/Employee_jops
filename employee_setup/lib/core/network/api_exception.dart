import 'package:dio/dio.dart';

/// Base exception for all API-related failures.
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic rawData;

  const ApiException({
    required this.message,
    this.statusCode,
    this.rawData,
  });

  @override
  String toString() => message;
}

/// 400 Bad Request / Validation Failure
class ValidationException extends ApiException {
  final List<String> errors;

  const ValidationException({
    required super.message,
    super.statusCode = 400,
    this.errors = const [],
    super.rawData,
  });
}

/// 401 Unauthorized (Expired or invalid token)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    required super.message,
    super.statusCode = 401,
    super.rawData,
  });
}

/// 403 Forbidden (Permission or role restriction)
class ForbiddenException extends ApiException {
  const ForbiddenException({
    required super.message,
    super.statusCode = 403,
    super.rawData,
  });
}

/// 404 Not Found
class NotFoundException extends ApiException {
  const NotFoundException({
    required super.message,
    super.statusCode = 404,
    super.rawData,
  });
}

/// 409 Conflict (e.g. Duplicate punch, overlapping leave)
class ConflictException extends ApiException {
  const ConflictException({
    required super.message,
    super.statusCode = 409,
    super.rawData,
  });
}

/// 429 Too Many Requests (Rate limit)
class RateLimitException extends ApiException {
  final int? retryAfterSeconds;

  const RateLimitException({
    required super.message,
    super.statusCode = 429,
    this.retryAfterSeconds,
    super.rawData,
  });
}

/// 500 / 502 / 503 Internal Server Error
class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.statusCode = 500,
    super.rawData,
  });
}

/// Network Connectivity / Timeout / Host Unreachable
class NetworkException extends ApiException {
  const NetworkException({
    required super.message,
    super.statusCode,
    super.rawData,
  });
}

/// Unknown or Unexpected Error
class UnknownApiException extends ApiException {
  const UnknownApiException({
    required super.message,
    super.statusCode,
    super.rawData,
  });
}

/// Factory utility to map DioException into strongly typed ApiException.
class ApiExceptionMapper {
  ApiExceptionMapper._();

  static ApiException fromDioException(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please check your internet connection.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Server unreachable. Please verify that the server is online.',
        );
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      case DioExceptionType.badResponse:
        return _fromResponse(dioError.response);
      default:
        return UnknownApiException(
          message: dioError.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  static ApiException _fromResponse(Response? response) {
    if (response == null) {
      return const UnknownApiException(message: 'Empty response received.');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String message = 'An error occurred (${response.statusCode})';
    List<String> errors = [];

    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        message = data['message'] as String;
      } else if (data['message'] is List) {
        errors = (data['message'] as List).map((e) => e.toString()).toList();
        message = errors.isNotEmpty ? errors.first : message;
      } else if (data['error'] is String) {
        message = data['error'] as String;
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    switch (statusCode) {
      case 400:
      case 422:
        return ValidationException(
          message: message,
          statusCode: statusCode,
          errors: errors,
          rawData: data,
        );
      case 401:
        return UnauthorizedException(
          message: message,
          statusCode: 401,
          rawData: data,
        );
      case 403:
        return ForbiddenException(
          message: message,
          statusCode: 403,
          rawData: data,
        );
      case 404:
        return NotFoundException(
          message: message,
          statusCode: 404,
          rawData: data,
        );
      case 409:
        return ConflictException(
          message: message,
          statusCode: 409,
          rawData: data,
        );
      case 429:
        return RateLimitException(
          message: message,
          statusCode: 429,
          rawData: data,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: 'Server error ($statusCode): $message',
          statusCode: statusCode,
          rawData: data,
        );
      default:
        return UnknownApiException(
          message: message,
          statusCode: statusCode,
          rawData: data,
        );
    }
  }
}
