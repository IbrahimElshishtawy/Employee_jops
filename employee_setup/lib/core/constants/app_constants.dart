/// Application-wide constants, geofence parameters, and mock defaults.
class AppConstants {
  AppConstants._();

  static const String appName = 'CyberWise IE';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // Geofence Parameters for Attendance
  static const double officeLatitude = 30.044400; // CyberWise IE - Test Office
  static const double officeLongitude = 31.235700;
  static const double maxAllowedDistanceMeters = 4.0; // 4 meters max rule

  // Default Canonical Test Employee (DEVICE_TEST_DATA)
  static const String mockEmployeeId = 'TEST-001';
  static const String mockEmployeeName = 'Device Test Employee';
  static const String mockEmployeeEmail = 'employee.test@example.com';
  static const String mockEmployeeDepartment = 'الهندسة البرمجية';
  static const String mockEmployeeJobTitle = 'Senior Software Developer';
  static const String mockEmployeeAvatar = '';
  static const String mockWorkLocationId = 'LOC-TEST-OFFICE';
  static const String mockWorkLocationName = 'CyberWise IE - Test Office';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'user_data';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyPendingAttendance = 'pending_attendance_queue';
  static const String keyReadNotifications = 'read_notifications_ids';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyEmployeeProfile = 'employee_profile';
}
