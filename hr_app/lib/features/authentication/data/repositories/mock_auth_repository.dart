import '../../../../core/errors/app_exception.dart';
import '../../../../core/rbac/app_role.dart';
import '../../../../core/security/token_storage.dart';
import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock Authentication Repository for development and testing
class MockAuthRepository implements AuthRepository {
  final TokenStorage _tokenStorage;
  AuthUser? _cachedUser;

  MockAuthRepository(this._tokenStorage);

  static final List<AuthUser> _mockUsers = [
    const AuthUser(
      id: 'TEST-EMP-001',
      email: 'admin@cyberwise.test',
      fullName: 'Super Administrator (Test)',
      role: AppRole.superAdmin,
      department: 'Executive HR',
    ),
    const AuthUser(
      id: 'TEST-EMP-002',
      email: 'hr.admin@cyberwise.test',
      fullName: 'HR Admin (Test)',
      role: AppRole.hrAdmin,
      department: 'Human Resources',
    ),
    const AuthUser(
      id: 'TEST-EMP-003',
      email: 'hr.manager@cyberwise.test',
      fullName: 'HR Manager (Test)',
      role: AppRole.hrManager,
      department: 'Operations',
    ),
    const AuthUser(
      id: 'TEST-EMP-004',
      email: 'hr.staff@cyberwise.test',
      fullName: 'HR Staff (Test)',
      role: AppRole.hrEmployee,
      department: 'Payroll & Records',
    ),
    const AuthUser(
      id: 'TEST-EMP-005',
      email: 'viewer@cyberwise.test',
      fullName: 'Audit Viewer (Test)',
      role: AppRole.viewer,
      department: 'Compliance',
    ),
  ];

  @override
  Future<AuthSession> login(AuthCredentials credentials) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final matchingUser = _mockUsers.firstWhere(
      (u) => u.email.toLowerCase() == credentials.email.trim().toLowerCase(),
      orElse: () => _mockUsers.first, // fallback to SuperAdmin for dev convenience
    );

    if (credentials.password.isEmpty) {
      throw const ValidationException(message: 'Password is required');
    }

    _cachedUser = matchingUser;
    const dummyToken = 'mock_jwt_access_token_cyberwise_hr_test';
    const dummyRefresh = 'mock_jwt_refresh_token_cyberwise_hr_test';

    await _tokenStorage.saveTokens(
      accessToken: dummyToken,
      refreshToken: dummyRefresh,
    );

    return AuthSession(
      user: matchingUser,
      accessToken: dummyToken,
      refreshToken: dummyRefresh,
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _cachedUser = null;
    await _tokenStorage.clearTokens();
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final hasToken = await _tokenStorage.hasValidToken();
    if (!hasToken) return null;
    _cachedUser ??= _mockUsers.first;
    return _cachedUser;
  }

  @override
  Future<AuthSession> refreshToken(String currentRefreshToken) async {
    final user = _cachedUser ?? _mockUsers.first;
    return AuthSession(
      user: user,
      accessToken: 'mock_refreshed_access_token',
      refreshToken: currentRefreshToken,
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
    );
  }
}
