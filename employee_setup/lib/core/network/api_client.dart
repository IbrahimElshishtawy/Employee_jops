import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/local_storage.dart';
import 'api_exception.dart';
import 'api_interceptors.dart';
import 'api_response.dart';

/// Centralized API Client managing all network communications for the Employee App.
class ApiClient {
  final Dio _dio;
  final LocalStorage storage;
  final AppConfig config;

  ApiClient({
    required this.storage,
    AppConfig? config,
    void Function()? onSessionExpired,
    Dio? customDio,
  })  : config = config ?? AppConfig.current,
        _dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: (config ?? AppConfig.current).apiBaseUrl,
                connectTimeout: (config ?? AppConfig.current).connectTimeout,
                receiveTimeout: (config ?? AppConfig.current).receiveTimeout,
                sendTimeout: (config ?? AppConfig.current).sendTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'Accept-Encoding': 'gzip, deflate, br',
                  'Connection': 'keep-alive',
                },
              ),
            ) {
    if (customDio == null) {
      _dio.interceptors.addAll([
        AuthInterceptor(storage: storage),
        RefreshTokenInterceptor(
          dio: _dio,
          storage: storage,
          onSessionExpired: onSessionExpired,
        ),
        LoggingInterceptor(enabled: this.config.enableNetworkLogs),
      ]);
    }
  }

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<dynamic>> _inFlightRequests = {};

  Dio get rawDio => _dio;

  /// Update base URL dynamically (e.g. from developer settings or environments)
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  /// Invalidate specific or all cached responses
  void clearCache([String? pattern]) {
    if (pattern == null) {
      _cache.clear();
    } else {
      _cache.removeWhere((key, _) => key.contains(pattern));
    }
  }

  /// High-performance GET request with in-flight deduplication and optional TTL caching.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromData,
    Duration? cacheDuration,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$path?${queryParameters?.toString() ?? ''}';

    if (!forceRefresh && cacheDuration != null && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        return ApiResponse<T>.fromJson(
          entry.response,
          fromData,
          statusCode: 200,
        );
      } else {
        _cache.remove(cacheKey);
      }
    }

    if (_inFlightRequests.containsKey(cacheKey)) {
      try {
        final rawData = await _inFlightRequests[cacheKey]!;
        return ApiResponse<T>.fromJson(
          rawData,
          fromData,
          statusCode: 200,
        );
      } catch (_) {}
    }

    final future = () async {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      if (cacheDuration != null &&
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        _cache[cacheKey] =
            _CacheEntry(response.data, DateTime.now().add(cacheDuration));
      }
      return response.data;
    }();

    _inFlightRequests[cacheKey] = future;

    try {
      final rawData = await future;
      return ApiResponse<T>.fromJson(
        rawData,
        fromData,
        statusCode: 200,
      );
    } on DioException catch (e) {
      throw ApiExceptionMapper.fromDioException(e);
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromData,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiExceptionMapper.fromDioException(e);
    }
  }

  /// Generic PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromData,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiExceptionMapper.fromDioException(e);
    }
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromData,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiExceptionMapper.fromDioException(e);
    }
  }

  /// Upload file multipart or base64
  Future<ApiResponse<T>> uploadFile<T>(
    String path, {
    required FormData formData,
    void Function(int count, int total)? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic data)? fromData,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return ApiResponse<T>.fromJson(
        response.data,
        fromData,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiExceptionMapper.fromDioException(e);
    }
  }
}

class _CacheEntry {
  final dynamic response;
  final DateTime expiresAt;
  _CacheEntry(this.response, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

