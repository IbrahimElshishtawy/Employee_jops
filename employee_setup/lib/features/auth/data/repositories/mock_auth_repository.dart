import 'dart:async';
import '../../domain/models/employee.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_auth_datasource.dart';

class MockAuthRepository implements AuthRepository {
  final MockAuthDataSource _dataSource;
  final StreamController<Employee?> _authStreamController = StreamController<Employee?>.broadcast();
  Employee? _currentUser;

  MockAuthRepository(this._dataSource);

  @override
  Stream<Employee?> get authStateChanges => _authStreamController.stream;

  @override
  Future<Employee?> getCurrentUser() async {
    _currentUser = await _dataSource.getCachedEmployee();
    _authStreamController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<Employee> signInWithGoogle() async {
    final user = await _dataSource.mockGoogleSignIn();
    _currentUser = user;
    _authStreamController.add(_currentUser);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _dataSource.clearSession();
    _currentUser = null;
    _authStreamController.add(null);
  }
}
