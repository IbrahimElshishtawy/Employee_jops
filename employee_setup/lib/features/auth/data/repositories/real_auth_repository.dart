import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_database.dart';
import '../../../../core/mock/models/app_session.dart';
import '../../domain/models/employee.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/real_auth_datasource.dart';

class RealAuthRepository implements AuthRepository {
  final RealAuthDataSource _dataSource;
  final Ref? _ref;
  final StreamController<Employee?> _authStreamController =
      StreamController<Employee?>.broadcast();

  RealAuthRepository(this._dataSource, [Ref? ref]) : _ref = ref;

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
    final user = await _dataSource.signInWithGoogle(fallbackEmail: email);

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
