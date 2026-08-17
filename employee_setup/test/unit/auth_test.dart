import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:employee_setup/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:employee_setup/features/auth/domain/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Feature Tests', () {
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

    test('Initial user is null before login', () async {
      final user = await repository.getCurrentUser();
      expect(user, isNull);
    });

    test('Google Sign-In logs in default employee', () async {
      final user = await repository.signInWithGoogle();
      expect(user.id, equals('EMP-1024'));
      expect(user.name, equals('إبراهيم الششتاوي'));
      expect(user.email, equals('employee@company.com'));

      final cached = await repository.getCurrentUser();
      expect(cached, isNotNull);
      expect(cached?.id, equals('EMP-1024'));
    });

    test('SignOut clears session and user state', () async {
      await repository.signInWithGoogle();
      expect(await repository.getCurrentUser(), isNotNull);

      await repository.signOut();
      expect(await repository.getCurrentUser(), isNull);
    });

    test('Employee model JSON serialization works correctly', () {
      final employee = Employee.defaultMock;
      final json = employee.toJson();
      final fromJson = Employee.fromJson(json);

      expect(fromJson.id, equals(employee.id));
      expect(fromJson.name, equals(employee.name));
      expect(fromJson.email, equals(employee.email));
    });
  });
}
