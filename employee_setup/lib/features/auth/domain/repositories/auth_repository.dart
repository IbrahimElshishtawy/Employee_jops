import '../models/employee.dart';

abstract class AuthRepository {
  Future<Employee?> getCurrentUser();
  Future<Employee> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<Employee> signInWithGoogle({String? email});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> updateEmployee(Employee employee);
  Future<void> signOut();
  Stream<Employee?> get authStateChanges;
}
