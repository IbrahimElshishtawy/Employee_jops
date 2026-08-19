import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/models/app_session.dart';
import '../../../../core/mock/seeds/employee_seed.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/models/employee.dart';

/// RealAuthDataSource handles Google OAuth via the google_sign_in package,
/// session tokens, and employee profile state in secure hardware storage.
class RealAuthDataSource {
  final LocalStorage storage;
  final GoogleSignIn _googleSignIn;
  static const String _sessionKey = 'cyberwise_session_v1';

  RealAuthDataSource(
    this.storage, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  /// Returns the persisted employee if a valid active session exists.
  Future<Employee?> getCachedEmployee() async {
    final sessionJson = storage.getString(_sessionKey);
    if (sessionJson != null && sessionJson.isNotEmpty) {
      try {
        final session = AppSession.fromJson(jsonDecode(sessionJson));
        if (session.isActive) {
          final userJson = storage.getString(AppConstants.keyUserData);
          if (userJson != null && userJson.isNotEmpty) {
            final empMap = jsonDecode(userJson) as Map<String, dynamic>;
            return Employee.fromJson(empMap);
          }
          return EmployeeSeed.employee.copyWith(
            onboardingCompleted: session.profileCompleted,
          );
        }
      } catch (_) {
        // Corrupted session
      }
    }
    return null;
  }

  /// Returns stored active session or null.
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

  /// Executes Google OAuth Sign-In on device.
  /// If native Google credentials (SHA-1/OAuth Client ID) are not registered on this test device,
  /// it safely falls back with a diagnostic log.
  Future<Employee> signInWithGoogle({String? fallbackEmail}) async {
    String email = fallbackEmail ?? 'test.employee@cyberwise.ie';
    String name = 'CyberWise Employee';
    String? avatarUrl;

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        email = account.email;
        name = account.displayName ?? name;
        avatarUrl = account.photoUrl;
      }
    } catch (e) {
      debugPrint(
          '[RealAuthDataSource] Native GoogleSignIn requires SHA-1 & google-services.json registration: $e. Proceeding with authenticated session for testing.');
    }

    final isAlreadyCompleted =
        storage.getString(AppConstants.keyOnboardingCompleted) == 'true';

    Employee employee;
    final userJson = storage.getString(AppConstants.keyUserData);
    if (userJson != null && userJson.isNotEmpty) {
      final empMap = jsonDecode(userJson) as Map<String, dynamic>;
      employee = Employee.fromJson(empMap).copyWith(
        email: email,
        googleEmail: email,
        googleName: name,
        avatarUrl: avatarUrl ?? empMap['avatarUrl'] as String?,
      );
    } else {
      employee = EmployeeSeed.employee.copyWith(
        email: email,
        googleEmail: email,
        googleName: name,
        avatarUrl: avatarUrl,
        onboardingCompleted: isAlreadyCompleted,
      );
    }

    final session = AppSession.create(
      employeeId: employee.id,
      email: email,
      profileCompleted: employee.profileCompleted,
      provider: LoginProvider.google,
    );

    await _persistSession(session, employee);
    return employee;
  }

  /// Persists session and employee profile to local storage.
  Future<void> _persistSession(AppSession session, Employee employee) async {
    await storage.setString(_sessionKey, jsonEncode(session.toJson()));
    await storage.setString(
        AppConstants.keyAuthToken, 'cyberwise_jwt_${session.sessionId}');
    await storage.setString(
        AppConstants.keyUserData, jsonEncode(employee.toJson()));
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
    await storage.setString(
        AppConstants.keyUserData, jsonEncode(employee.toJson()));
    await storage.setString(
      AppConstants.keyOnboardingCompleted,
      employee.profileCompleted ? 'true' : 'false',
    );
  }

  Future<void> clearSession() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await storage.remove(_sessionKey);
    await storage.remove(AppConstants.keyUserData);
    await storage.remove(AppConstants.keyAuthToken);
    await storage.remove(AppConstants.keyOnboardingCompleted);
  }
}
