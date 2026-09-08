import 'dart:async';
import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/local_storage.dart';
import '../utils/secure_logger.dart';
import 'api_endpoints.dart';

/// Injects RFC 6750 Bearer JWT token into outgoing requests.
class AuthInterceptor extends QueuedInterceptor {
  final LocalStorage storage;
  final List<String> publicEndpoints;

  AuthInterceptor({
    required this.storage,
    this.publicEndpoints = const [
      ApiEndpoints.login,
      ApiEndpoints.googleAuth,
      ApiEndpoints.refreshToken,
      ApiEndpoints.healthLive,
      ApiEndpoints.publicSettings,
    ],
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = publicEndpoints.any((endpoint) => options.path.contains(endpoint));

    if (!isPublic) {
      final token = storage.getString(AppConstants.keyAuthToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }
}

/// Automatically intercepts HTTP 401 Unauthorized, locks queue,
/// refreshes access token using Refresh Token, and replays failed requests.
class RefreshTokenInterceptor extends QueuedInterceptor {
  final Dio dio;
  final LocalStorage storage;
  final void Function()? onSessionExpired;
  Completer<String?>? _refreshCompleter;

  RefreshTokenInterceptor({
    required this.dio,
    required this.storage,
    this.onSessionExpired,
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final isRefreshCall = err.requestOptions.path.contains(ApiEndpoints.refreshToken);
    final isLoginCall = err.requestOptions.path.contains(ApiEndpoints.login) ||
        err.requestOptions.path.contains(ApiEndpoints.googleAuth);

    if (statusCode == 401 && !isRefreshCall && !isLoginCall) {
      try {
        final newAccessToken = await _executeTokenRefresh();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Replay the failed request with the fresh Access Token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await dio.fetch(options);
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        SecureLogger.error('RefreshTokenInterceptor', 'Token refresh failed', e);
      }

      // Refresh completely failed or refresh token expired — expire session
      onSessionExpired?.call();
    }

    return handler.next(err);
  }

  Future<String?> _executeTokenRefresh() async {
    // If a refresh operation is already running, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = storage.getString(AppConstants.keyRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      // Create a clean Dio instance to avoid interceptor loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String? newAccessToken;
        String? newRefreshToken;

        if (data is Map<String, dynamic>) {
          final payload = data['data'] is Map<String, dynamic> ? data['data'] : data;
          newAccessToken = payload['accessToken'] as String?;
          newRefreshToken = payload['refreshToken'] as String?;
        }

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storage.setString(AppConstants.keyAuthToken, newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await storage.setString(AppConstants.keyRefreshToken, newRefreshToken);
          }
          _refreshCompleter!.complete(newAccessToken);
          return newAccessToken;
        }
      }

      _refreshCompleter!.complete(null);
      return null;
    } catch (e) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }
}

/// Sanitized network logger for debug builds that redacts sensitive keys.
class LoggingInterceptor extends Interceptor {
  final bool enabled;

  LoggingInterceptor({this.enabled = true});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      SecureLogger.info(
        'HTTP',
        '--> ${options.method} ${options.baseUrl}${options.path}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      SecureLogger.info(
        'HTTP',
        '<-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      SecureLogger.error(
        'HTTP',
        '<-- ERROR ${err.response?.statusCode ?? "ERR"} ${err.requestOptions.method} ${err.requestOptions.path}: ${err.message}',
      );
    }
    handler.next(err);
  }
}
