import 'package:shared_preferences/shared_preferences.dart';

/// Abstract Token Storage contract for session tokens
abstract class TokenStorage {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<bool> hasValidToken();
}

/// SharedPreferences-backed Token Storage implementation
class SharedPrefsTokenStorage implements TokenStorage {
  static const String _accessTokenKey = 'cw_hr_access_token';
  static const String _refreshTokenKey = 'cw_hr_refresh_token';

  final SharedPreferences _prefs;

  SharedPrefsTokenStorage(this._prefs);

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  @override
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
