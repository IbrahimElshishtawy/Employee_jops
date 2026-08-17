import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/models/employee.dart';

class MockAuthDataSource {
  final LocalStorage storage;

  MockAuthDataSource(this.storage);

  Future<Employee?> getCachedEmployee() async {
    final jsonStr = storage.getString(AppConstants.keyUserData);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return Employee.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<Employee> mockGoogleSignIn() async {
    // Artificial slight delay to simulate Google Auth Flow
    await Future.delayed(const Duration(milliseconds: 650));
    final employee = Employee.defaultMock;
    await storage.setString(AppConstants.keyUserData, jsonEncode(employee.toJson()));
    await storage.setString(AppConstants.keyAuthToken, 'mock_jwt_token_emp_1024');
    return employee;
  }

  Future<void> clearSession() async {
    await storage.remove(AppConstants.keyUserData);
    await storage.remove(AppConstants.keyAuthToken);
  }
}
