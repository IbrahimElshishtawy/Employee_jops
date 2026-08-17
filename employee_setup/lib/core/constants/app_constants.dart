/// Application-wide constants, geofence parameters, and mock defaults.
class AppConstants {
  AppConstants._();

  static const String appName = 'Employee App';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // Geofence Parameters for Attendance
  static const double officeLatitude = 30.0444; // Example HQ
  static const double officeLongitude = 31.2357;
  static const double maxAllowedDistanceMeters = 4.0; // 4 meters max rule

  // Default Mock Employee
  static const String mockEmployeeId = 'EMP-1024';
  static const String mockEmployeeName = 'إبراهيم الششتاوي';
  static const String mockEmployeeEmail = 'employee@company.com';
  static const String mockEmployeeDepartment = 'الهندسة البرمجية (Engineering)';
  static const String mockEmployeeJobTitle = 'Software Developer';
  static const String mockEmployeeAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'user_data';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyPendingAttendance = 'pending_attendance_queue';
  static const String keyReadNotifications = 'read_notifications_ids';
}
