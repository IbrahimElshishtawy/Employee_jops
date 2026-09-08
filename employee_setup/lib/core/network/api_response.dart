/// Generic API response wrapper for NestJS Fastify backend.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.meta,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    dynamic json,
    T Function(dynamic rawData)? fromData, {
    int? statusCode,
  }) {
    if (json is Map<String, dynamic>) {
      final success = json['success'] as bool? ?? (statusCode != null && statusCode >= 200 && statusCode < 300);
      final rawData = json.containsKey('data') ? json['data'] : json;
      final message = json['message'] is String ? json['message'] as String : null;
      final meta = json['meta'] is Map<String, dynamic> ? json['meta'] as Map<String, dynamic> : null;

      final parsedData = (rawData != null && fromData != null) ? fromData(rawData) : (rawData as T?);

      return ApiResponse<T>(
        success: success,
        data: parsedData,
        message: message,
        meta: meta,
        statusCode: statusCode,
      );
    }

    return ApiResponse<T>(
      success: statusCode != null && statusCode >= 200 && statusCode < 300,
      data: fromData != null ? fromData(json) : json as T?,
      statusCode: statusCode,
    );
  }
}
