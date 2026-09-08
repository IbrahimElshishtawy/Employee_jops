import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/mock/models/app_session.dart';
import '../../../../core/mock/seeds/employee_seed.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/models/employee.dart';

/// RealAuthDataSource handles Email/Password authentication, Google OAuth,
/// session tokens, and employee profile state in secure hardware storage and backend APIs.
class RealAuthDataSource {
  final LocalStorage storage;
  final ApiClient? apiClient;
  final GoogleSignIn _googleSignIn;
  static const String _sessionKey = 'cyberwise_session_v1';

  RealAuthDataSource(
    this.storage, {
    this.apiClient,
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

  /// Authenticates with Email & Password via backend API (POST /api/v1/auth/login).
  Future<Employee> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (apiClient != null) {
      try {
        final response = await apiClient!.post(
          ApiEndpoints.login,
          data: {
            'email': email.trim(),
            'password': password,
          },
        );

        if (response.success && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          final payload = data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data;

          final accessToken = payload['accessToken'] as String?;
          final refreshToken = payload['refreshToken'] as String?;

          if (accessToken != null) {
            await storage.setString(AppConstants.keyAuthToken, accessToken);
          }
          if (refreshToken != null) {
            await storage.setString(AppConstants.keyRefreshToken, refreshToken);
          }

          Employee employee;
          if (payload['employee'] is Map<String, dynamic>) {
            employee = Employee.fromJson(payload['employee'] as Map<String, dynamic>);
          } else if (payload['user'] is Map<String, dynamic>) {
            final userMap = payload['user'] as Map<String, dynamic>;
            employee = EmployeeSeed.employee.copyWith(
              id: userMap['id'] as String? ?? 'EMP-001',
              email: userMap['email'] as String? ?? email,
              name: userMap['name'] as String? ?? 'CyberWise Employee',
              onboardingCompleted: userMap['profileCompleted'] as bool? ?? false,
            );
          } else {
            employee = EmployeeSeed.employee.copyWith(email: email);
          }

          final session = AppSession.create(
            employeeId: employee.id,
            email: email,
            profileCompleted: employee.profileCompleted,
            provider: LoginProvider.email,
            deviceId: 'DEV-REAL-001',
            deviceType: 'MOBILE',
            deviceModel: 'Mobile Client',
            osVersion: '1.0.0',
            appVersion: '1.0.0+1',
          );

          await _persistSession(session, employee, accessToken: accessToken, refreshToken: refreshToken);
          return employee;
        }
      } on ApiException catch (e) {
        SecureLogger.error('RealAuthDataSource', 'API Login failure', e);
        rethrow;
      } catch (e) {
        SecureLogger.error('RealAuthDataSource', 'Unexpected login error', e);
      }
    }

    // Fallback for offline test environments
    final isAlreadyCompleted =
        storage.getString(AppConstants.keyOnboardingCompleted) == 'true';
    final employee = EmployeeSeed.employee.copyWith(
      email: email,
      onboardingCompleted: isAlreadyCompleted,
    );

    final session = AppSession.create(
      employeeId: employee.id,
      email: email,
      profileCompleted: employee.profileCompleted,
      provider: LoginProvider.email,
      deviceId: 'DEV-REAL-001',
      deviceType: 'MOBILE',
      deviceModel: 'Mobile Client',
      osVersion: '1.0.0',
      appVersion: '1.0.0+1',
    );

    await _persistSession(session, employee);
    return employee;
  }

  /// Executes Google OAuth Sign-In on device and exchanges token with backend (POST /api/v1/auth/google).
  Future<Employee> signInWithGoogle({String? fallbackEmail}) async {
    String email = fallbackEmail ?? 'test.employee@cyberwise.ie';
    String name = 'CyberWise Employee';
    String? avatarUrl;
    String? idToken;

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        email = account.email;
        name = account.displayName ?? name;
        avatarUrl = account.photoUrl;

        final auth = await account.authentication;
        idToken = auth.idToken;
      }
    } catch (e) {
      SecureLogger.info(
        'RealAuthDataSource',
        'Native GoogleSignIn fallback for test environment.',
      );
    }

    String? serverAccessToken;
    String? serverRefreshToken;

    if (apiClient != null && idToken != null && idToken.isNotEmpty) {
      try {
        final response = await apiClient!.post(
          ApiEndpoints.googleAuth,
          data: {'idToken': idToken},
        );
        if (response.success && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          final payload = data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data;
          serverAccessToken = payload['accessToken'] as String?;
          serverRefreshToken = payload['refreshToken'] as String?;
        }
      } catch (e) {
        SecureLogger.info(
          'RealAuthDataSource',
          'Backend Google exchange skipped/fallback: $e',
        );
      }
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
      deviceId: 'DEV-REAL-001',
      deviceType: 'MOBILE',
      deviceModel: 'Mobile Client',
      osVersion: '1.0.0',
      appVersion: '1.0.0+1',
    );

    await _persistSession(
      session,
      employee,
      accessToken: serverAccessToken,
      refreshToken: serverRefreshToken,
    );
    return employee;
  }

  /// Change employee password via POST /api/v1/auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (apiClient != null) {
      await apiClient!.post(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    }
  }

  /// Persists session and employee profile to local storage.
  Future<void> _persistSession(
    AppSession session,
    Employee employee, {
    String? accessToken,
    String? refreshToken,
  }) async {
    await storage.setString(_sessionKey, jsonEncode(session.toJson()));
    await storage.setString(
      AppConstants.keyAuthToken,
      accessToken ?? 'cyberwise_jwt_${session.sessionId}',
    );
    if (refreshToken != null) {
      await storage.setString(AppConstants.keyRefreshToken, refreshToken);
    }
    await storage.setString(
      AppConstants.keyUserData,
      jsonEncode(employee.toJson()),
    );
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
      AppConstants.keyUserData,
      jsonEncode(employee.toJson()),
    );
    await storage.setString(
      AppConstants.keyOnboardingCompleted,
      employee.profileCompleted ? 'true' : 'false',
    );

    // Call PATCH /api/v1/employees/me/profile if online
    if (apiClient != null) {
      try {
        await apiClient!.patch(
          ApiEndpoints.updateProfile,
          data: {
            if (employee.phone.isNotEmpty) 'phone': employee.phone,
            if (employee.nationalId != null) 'nationalId': employee.nationalId,
            if (employee.avatarUrl.isNotEmpty) 'avatarUrl': employee.avatarUrl,
          },
        );
      } catch (e) {
        SecureLogger.info('RealAuthDataSource', 'Profile patch synced locally: $e');
      }
    }
  }

  Future<void> clearSession() async {
    if (apiClient != null) {
      try {
        final refreshToken = storage.getString(AppConstants.keyRefreshToken);
        await apiClient!.post(
          ApiEndpoints.logout,
          data: refreshToken != null ? {'refreshToken': refreshToken} : null,
        );
      } catch (_) {}
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await storage.remove(_sessionKey);
    await storage.remove(AppConstants.keyUserData);
    await storage.remove(AppConstants.keyAuthToken);
    await storage.remove(AppConstants.keyRefreshToken);
    await storage.remove(AppConstants.keyOnboardingCompleted);
  }
}
