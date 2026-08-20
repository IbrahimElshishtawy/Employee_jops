import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/token_storage.dart';
import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_dto.dart';

/// Production Live API Authentication Repository
class ApiAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  ApiAuthRepository(this._apiClient, this._tokenStorage);

  @override
  Future<AuthSession> login(AuthCredentials credentials) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: {
          'email': credentials.email,
          'password': credentials.password,
        },
        parser: (data) => AuthSessionDto.fromJson(data as Map<String, dynamic>),
      );

      final sessionDto = response.data!;
      final session = sessionDto.toDomain();

      await _tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );

      return session;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network errors during logout
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final hasToken = await _tokenStorage.hasValidToken();
    if (!hasToken) return null;

    try {
      final response = await _apiClient.get(
        ApiEndpoints.currentUser,
        parser: (data) => AuthUserDto.fromJson(data as Map<String, dynamic>),
      );
      return response.data?.toDomain();
    } catch (e) {
      await _tokenStorage.clearTokens();
      return null;
    }
  }

  @override
  Future<AuthSession> refreshToken(String currentRefreshToken) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        body: {'refreshToken': currentRefreshToken},
        parser: (data) => AuthSessionDto.fromJson(data as Map<String, dynamic>),
      );
      final session = response.data!.toDomain();
      await _tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return session;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }
}
