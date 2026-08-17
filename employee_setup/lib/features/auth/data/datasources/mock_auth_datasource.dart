import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/models/app_session.dart';
import '../../../../core/mock/seeds/employee_seed.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/models/employee.dart';

class MockAuthDataSource {
  final LocalStorage storage;
  static const String _sessionKey = 'mock_session_v2';

  MockAuthDataSource(this.storage);

  /// Returns the persisted employee if a valid session exists.
  Future<Employee?> getCachedEmployee() async {
    final sessionJson = storage.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      try {
        final session = AppSession.fromJson(jsonDecode(sessionJson));
        if (session.isActive) {
          return EmployeeSeed.employee;
        }
      } catch (_) {
        // Corrupted session — treat as logged out
      }
    }
    return null;
  }

  /// Returns stored session or null.
  Future<AppSession?> getCachedSession() async {
    final sessionJson = storage.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      try {
        final session = AppSession.fromJson(jsonDecode(sessionJson));
        return session.isActive ? session : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Simulates Google OAuth with email validation.
  Future<Employee> mockGoogleSignIn(String email) async {
    await Future.delayed(const Duration(milliseconds: 650));
    if (email.toLowerCase() != EmployeeSeed.email) {
      throw Exception('البريد الإلكتروني غير مسجل في النظام');
    }
    final session = AppSession.create(
      employeeId: EmployeeSeed.id,
      email: EmployeeSeed.email,
      provider: LoginProvider.google,
    );
    await _persistSession(session);
    return EmployeeSeed.employee;
  }

  /// Persists session to local storage.
  Future<void> _persistSession(AppSession session) async {
    await storage.setString(_sessionKey, jsonEncode(session.toJson()));
    await storage.setString(AppConstants.keyAuthToken, 'mock_jwt_${session.sessionId}');
    await storage.setString(AppConstants.keyUserData, jsonEncode(EmployeeSeed.employee.toJson()));
  }

  Future<void> clearSession() async {
    await storage.remove(_sessionKey);
    await storage.remove(AppConstants.keyUserData);
    await storage.remove(AppConstants.keyAuthToken);
  }
}
