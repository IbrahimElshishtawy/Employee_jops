import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_database.dart';
import '../../../../core/mock/models/app_session.dart';
import '../../../../core/mock/seeds/employee_seed.dart';
import '../../domain/models/employee.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_auth_datasource.dart';

class MockAuthRepository implements AuthRepository {
  final MockAuthDataSource _dataSource;
  final Ref? _ref;
  final StreamController<Employee?> _authStreamController =
      StreamController<Employee?>.broadcast();

  MockAuthRepository(this._dataSource, [Ref? ref]) : _ref = ref;

  MockDatabaseNotifier get _db =>
      _ref?.read(mockDatabaseProvider.notifier) ?? fallbackMockDatabaseNotifier;

  @override
  Stream<Employee?> get authStateChanges => _authStreamController.stream;

  @override
  Future<Employee?> getCurrentUser() async {
    final employee = await _dataSource.getCachedEmployee();
    if (employee != null) {
      final session = await _dataSource.getCachedSession();
      if (session != null) {
        _db.setSession(session);
      }
      _db.setEmployee(employee);
    }
    _authStreamController.add(employee);
    return employee;
  }

  @override
  Future<Employee> signInWithGoogle({String? email}) async {
    final targetEmail = email ?? EmployeeSeed.email;
    final user = await _dataSource.mockGoogleSignIn(targetEmail);

    final session = await _dataSource.getCachedSession() ??
        AppSession.create(
          employeeId: user.id,
          email: user.email,
          profileCompleted: user.profileCompleted,
          provider: LoginProvider.google,
        );

    _db.setSession(session);
    _db.setEmployee(user);
    _authStreamController.add(user);
    return user;
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await _dataSource.updateEmployee(employee);
    _db.setEmployee(employee);
    final session = await _dataSource.getCachedSession();
    if (session != null) {
      _db.setSession(session);
    }
    _authStreamController.add(employee);
  }

  @override
  Future<void> signOut() async {
    await _dataSource.clearSession();
    _db.clearSession();
    _authStreamController.add(null);
  }
}
