import '../models/employee.dart';

abstract class AuthRepository {
  Future<Employee?> getCurrentUser();
  Future<Employee> signInWithGoogle();
  Future<void> signOut();
  Stream<Employee?> get authStateChanges;
}
