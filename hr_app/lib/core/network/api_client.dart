import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../errors/app_exception.dart';
import '../errors/error_handler.dart';
import 'api_response.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';

/// Centralized API Client contract
abstract class ApiClient {
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    T Function(dynamic data)? parser,
  });

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    T Function(dynamic data)? parser,
  });

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    T Function(dynamic data)? parser,
  });

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    T Function(dynamic data)? parser,
  });

  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic data)? parser,
  });
}

/// HTTP implementation of ApiClient
class HttpApiClient implements ApiClient {
  final http.Client _client;
  final AuthInterceptor _authInterceptor;

  HttpApiClient(this._client, this._authInterceptor);

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final base = EnvConfig.apiBaseUrl;
    final fullUrl = '$base$path';
    return Uri.parse(fullUrl).replace(queryParameters: queryParams);
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    T Function(dynamic data)? parser,
  }) async {
    final uri = _buildUri(path, queryParams);
    return _sendRequest<T>('GET', uri, parser: parser);
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    T Function(dynamic data)? parser,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest<T>('POST', uri, body: body, parser: parser);
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    T Function(dynamic data)? parser,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest<T>('PUT', uri, body: body, parser: parser);
  }

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    T Function(dynamic data)? parser,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest<T>('PATCH', uri, body: body, parser: parser);
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic data)? parser,
  }) async {
    final uri = _buildUri(path);
    return _sendRequest<T>('DELETE', uri, parser: parser);
  }

  Future<ApiResponse<T>> _sendRequest<T>(
    String method,
    Uri uri, {
    dynamic body,
    T Function(dynamic data)? parser,
  }) async {
    try {
      final headers = await _authInterceptor.interceptRequest(null);
      LoggingInterceptor.logRequest(method, uri.toString(), headers: headers, body: body);

      final encodedBody = body != null ? jsonEncode(body) : null;
      http.Response response;

      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(uri, headers: headers, body: encodedBody);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: headers, body: encodedBody);
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: headers, body: encodedBody);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw UnknownException(message: 'Unsupported HTTP method: $method');
      }

      LoggingInterceptor.logResponse(method, uri.toString(), response.statusCode);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.fromJson(decoded, parser);
      } else {
        throw ErrorHandler.fromStatusCode(
          response.statusCode,
          message: 'Server error with code ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      LoggingInterceptor.logError(method, uri.toString(), e);
      throw NetworkException(message: 'Network unreachable', details: e);
    } catch (e) {
      LoggingInterceptor.logError(method, uri.toString(), e);
      if (e is AppException) rethrow;
      throw UnknownException(message: e.toString());
    }
  }
}
