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
  final Ref _ref;
  final StreamController<Employee?> _authStreamController =
      StreamController<Employee?>.broadcast();

  MockAuthRepository(this._dataSource, this._ref);

  MockDatabaseNotifier get _db => _ref.read(mockDatabaseProvider.notifier);

  @override
  Stream<Employee?> get authStateChanges => _authStreamController.stream;

  @override
  Future<Employee?> getCurrentUser() async {
    final employee = await _dataSource.getCachedEmployee();
    if (employee != null) {
      // Restore session into MockDatabase
      final session = await _dataSource.getCachedSession();
      if (session != null) {
        _db.setSession(session);
      }
    }
    _authStreamController.add(employee);
    return employee;
  }

  @override
  Future<Employee> signInWithGoogle() async {
    // Default to the seed email for the mock Google sign-in button
    final user = await _dataSource.mockGoogleSignIn(EmployeeSeed.email);

    // Create and persist a fresh session in MockDatabase
    final session = AppSession.create(
      employeeId: EmployeeSeed.id,
      email: EmployeeSeed.email,
      provider: LoginProvider.google,
    );
    _db.setSession(session);
    _authStreamController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _dataSource.clearSession();
    _db.clearSession();
    _authStreamController.add(null);
  }
}
