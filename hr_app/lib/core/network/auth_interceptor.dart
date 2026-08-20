import '../security/token_storage.dart';

/// Interceptor for injecting authorization headers
class AuthInterceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  Future<Map<String, String>> interceptRequest(Map<String, String>? baseHeaders) async {
    final headers = Map<String, String>.from(baseHeaders ?? {});
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
