import '../models/employee.dart';

abstract class AuthRepository {
  Future<Employee?> getCurrentUser();
  Future<Employee> signInWithGoogle({String? email});
  Future<void> updateEmployee(Employee employee);
  Future<void> signOut();
  Stream<Employee?> get authStateChanges;
}
