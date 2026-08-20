import '../entities/auth_credentials.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

/// Authentication Repository Contract
abstract class AuthRepository {
  Future<AuthSession> login(AuthCredentials credentials);
  Future<void> logout();
  Future<AuthUser?> getCurrentUser();
  Future<AuthSession> refreshToken(String currentRefreshToken);
}
