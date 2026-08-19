import 'dart:convert';
import 'package:employee_setup/core/constants/app_constants.dart';
import 'package:employee_setup/core/mock/models/app_session.dart';
import 'package:employee_setup/core/mock/seeds/employee_seed.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:employee_setup/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:employee_setup/features/auth/domain/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication, Session & Profile Completion Tests', () {
    late SharedPrefsStorage storage;
    late MockAuthDataSource dataSource;
    late MockAuthRepository repository;

    setUp(() async {
      storage = SharedPrefsStorage();
      await storage.init();
      await storage.clear();
      dataSource = MockAuthDataSource(storage);
      repository = MockAuthRepository(dataSource);
    });

    test('1. Initial app launch with no session returns null user', () async {
      final user = await repository.getCurrentUser();
      expect(user, isNull);
    });

    test('2. New Google user signs in: authenticated == true, profileCompleted == false', () async {
      final user = await repository.signInWithGoogle(email: EmployeeSeed.email);
      expect(user.id, equals('TEST-001'));
      expect(user.name, equals('Device Test Employee'));
      expect(user.email, equals('employee.test@example.com'));
      expect(user.profileCompleted, isFalse);
      expect(user.onboardingCompleted, isFalse);

      final session = await dataSource.getCachedSession();
      expect(session, isNotNull);
      expect(session!.isAuthenticated, isTrue);
      expect(session.profileCompleted, isFalse);
      expect(session.status, equals(SessionStatus.active));
      expect(session.dataSource, equals('DEVICE_TEST_DATA'));
    });

    test('3. Existing incomplete employee: profileCompleted == false directs to Onboarding', () async {
      final user = await repository.signInWithGoogle(email: EmployeeSeed.email);
      expect(user.profileCompleted, isFalse);

      final cached = await repository.getCurrentUser();
      expect(cached, isNotNull);
      expect(cached!.profileCompleted, isFalse);
    });

    test('4. Onboarding completion updates employee and session to profileCompleted == true', () async {
      final initialUser = await repository.signInWithGoogle(email: EmployeeSeed.email);
      expect(initialUser.profileCompleted, isFalse);

      final completedUser = initialUser.copyWith(
        nationalId: '30001010100000',
        phone: '01012345678',
        jobTitle: 'Senior Software Developer',
        department: 'الهندسة البرمجية',
        profileCompleted: true,
      );

      await repository.updateEmployee(completedUser);

      final reloadedUser = await repository.getCurrentUser();
      expect(reloadedUser, isNotNull);
      expect(reloadedUser!.profileCompleted, isTrue);
      expect(reloadedUser.onboardingCompleted, isTrue);

      final session = await dataSource.getCachedSession();
      expect(session!.profileCompleted, isTrue);
    });

    test('5. App restart with incomplete profile restores session and preserves incomplete state', () async {
      await repository.signInWithGoogle(email: EmployeeSeed.email);

      // Simulate App Restart with fresh instances pointing to same storage
      final restartDataSource = MockAuthDataSource(storage);
      final restartRepo = MockAuthRepository(restartDataSource);

      final resumedUser = await restartRepo.getCurrentUser();
      expect(resumedUser, isNotNull);
      expect(resumedUser!.profileCompleted, isFalse);

      final resumedSession = await restartDataSource.getCachedSession();
      expect(resumedSession, isNotNull);
      expect(resumedSession!.isActive, isTrue);
      expect(resumedSession.profileCompleted, isFalse);
    });

    test('6. App restart with complete profile restores session and lands on complete profile state', () async {
      final user = await repository.signInWithGoogle(email: EmployeeSeed.email);
      final completedUser = user.copyWith(
        nationalId: '30001010100000',
        phone: '01012345678',
        profileCompleted: true,
      );
      await repository.updateEmployee(completedUser);

      // Simulate App Restart
      final restartDataSource = MockAuthDataSource(storage);
      final restartRepo = MockAuthRepository(restartDataSource);

      final restoredUser = await restartRepo.getCurrentUser();
      expect(restoredUser, isNotNull);
      expect(restoredUser!.profileCompleted, isTrue);

      final restoredSession = await restartDataSource.getCachedSession();
      expect(restoredSession, isNotNull);
      expect(restoredSession!.profileCompleted, isTrue);
    });

    test('7. Logout clears session, profile cache, and tokens completely', () async {
      await repository.signInWithGoogle(email: EmployeeSeed.email);
      expect(await repository.getCurrentUser(), isNotNull);

      await repository.signOut();

      expect(await repository.getCurrentUser(), isNull);
      expect(await dataSource.getCachedSession(), isNull);
      expect(storage.getString(AppConstants.keyUserData), isNull);
      expect(storage.getString(AppConstants.keyAuthToken), isNull);
    });

    test('8. Session expiration invalidates session and rejects access', () async {
      final user = await repository.signInWithGoogle(email: EmployeeSeed.email);
      expect(user, isNotNull);

      // Mutate session in storage to be in the past (expired)
      final sessionJson = storage.getString('cyberwise_session_v1');
      expect(sessionJson, isNotNull);
      final sessionMap = jsonDecode(sessionJson!) as Map<String, dynamic>;
      sessionMap['expiresAt'] = DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      sessionMap['status'] = SessionStatus.expired.name;
      await storage.setString('cyberwise_session_v1', jsonEncode(sessionMap));

      final expiredUser = await repository.getCurrentUser();
      expect(expiredUser, isNull);

      final cachedSession = await dataSource.getCachedSession();
      expect(cachedSession, isNull);
    });

    test('9. Employee model JSON serialization with CyberWise IE branding and profileCompleted', () {
      final employee = Employee.defaultMock;
      final json = employee.toJson();
      final fromJson = Employee.fromJson(json);

      expect(fromJson.id, equals('TEST-001'));
      expect(fromJson.name, equals('Device Test Employee'));
      expect(fromJson.email, equals('employee.test@example.com'));
      expect(fromJson.workplaceName, equals('CyberWise IE - Test Office'));
      expect(fromJson.dataSource, equals('DEVICE_TEST_DATA'));
    });
  });
}
