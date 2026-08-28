import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/models/app_session.dart';
import '../../../../core/mock/seeds/employee_seed.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/models/employee.dart';

class MockAuthDataSource {
  final LocalStorage storage;
  static const String _sessionKey = 'cyberwise_session_v1';

  MockAuthDataSource(this.storage);

  /// Returns the persisted employee if a valid active session exists.
  Future<Employee?> getCachedEmployee() async {
    final sessionJson = storage.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      try {
        final session = AppSession.fromJson(jsonDecode(sessionJson));
        if (session.isActive) {
          // Check if employee profile is stored
          final userJson = storage.getString(AppConstants.keyUserData);
          if (userJson != null && userJson.isNotEmpty) {
            final empMap = jsonDecode(userJson) as Map<String, dynamic>;
            return Employee.fromJson(empMap);
          }
          // If no stored profile exists, return test seed with session's completion state
          return EmployeeSeed.employee.copyWith(
            onboardingCompleted: session.profileCompleted,
          );
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

  /// Simulates Google OAuth with email & profile completion validation.
  Future<Employee> mockGoogleSignIn(
    String email, {
    String? deviceId,
    String? deviceType,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    // Check if employee already completed profile previously in storage
    final isAlreadyCompleted = storage.getString(AppConstants.keyOnboardingCompleted) == 'true';

    Employee employee;
    final userJson = storage.getString(AppConstants.keyUserData);
    if (userJson != null && userJson.isNotEmpty) {
      final empMap = jsonDecode(userJson) as Map<String, dynamic>;
      employee = Employee.fromJson(empMap);
    } else {
      employee = EmployeeSeed.employee.copyWith(
        email: email,
        googleEmail: email,
        googleName: EmployeeSeed.name,
        onboardingCompleted: isAlreadyCompleted,
      );
    }

    final session = AppSession.create(
      employeeId: employee.id,
      email: email,
      profileCompleted: employee.profileCompleted,
      provider: LoginProvider.google,
      deviceId: deviceId ?? 'DEV-MOCK-ANDROID-001',
      deviceType: deviceType ?? 'ANDROID',
      deviceModel: deviceModel ?? 'Pixel 8 Pro',
      osVersion: osVersion ?? '14.0',
      appVersion: appVersion ?? '1.0.0+1',
    );

    await _persistSession(session, employee);
    return employee;
  }

  /// Persists session and employee profile to local storage.
  Future<void> _persistSession(AppSession session, Employee employee) async {
    await storage.setString(_sessionKey, jsonEncode(session.toJson()));
    await storage.setString(AppConstants.keyAuthToken, 'cyberwise_jwt_${session.sessionId}');
    await storage.setString(AppConstants.keyUserData, jsonEncode(employee.toJson()));
    await storage.setString(
      AppConstants.keyOnboardingCompleted,
      employee.profileCompleted ? 'true' : 'false',
    );
  }

  /// Update and persist employee profile (e.g. after onboarding completion)
  Future<void> updateEmployee(Employee employee) async {
    final session = await getCachedSession();
    if (session != null) {
      final updatedSession = session.copyWith(
        profileCompleted: employee.profileCompleted,
        lastActivityAt: DateTime.now(),
      );
      await storage.setString(_sessionKey, jsonEncode(updatedSession.toJson()));
    }
    await storage.setString(AppConstants.keyUserData, jsonEncode(employee.toJson()));
    await storage.setString(
      AppConstants.keyOnboardingCompleted,
      employee.profileCompleted ? 'true' : 'false',
    );
  }

  Future<void> clearSession() async {
    await storage.remove(_sessionKey);
    await storage.remove(AppConstants.keyUserData);
    await storage.remove(AppConstants.keyAuthToken);
    await storage.remove(AppConstants.keyOnboardingCompleted);
  }
}
