/// Authoritative backend endpoint definitions for CyberWise IE
class ApiEndpoints {
  ApiEndpoints._();

  // Authentication & Session
  static const String login = '/auth/hr/login';
  static const String logout = '/auth/hr/logout';
  static const String refreshToken = '/auth/hr/refresh-token';
  static const String currentUser = '/auth/hr/me';

  // Employees
  static const String employees = '/hr/employees';
  static String employeeDetails(String id) => '/hr/employees/$id';
  static String employeeStatus(String id) => '/hr/employees/$id/status';

  // Attendance
  static const String attendanceToday = '/hr/attendance/today';
  static const String attendanceHistory = '/hr/attendance/records';
  static const String attendanceExport = '/hr/attendance/export';

  // Unified Requests (Leave, Permission, Late, Absence, Half-Day)
  static const String requests = '/hr/requests';
  static String requestDetails(String id) => '/hr/requests/$id';
  static String requestReview(String id) => '/hr/requests/$id/review';

  // Advances
  static const String advances = '/hr/advances';
  static String advanceDetails(String id) => '/hr/advances/$id';
  static String advanceReview(String id) => '/hr/advances/$id/review';

  // Deductions
  static const String deductions = '/hr/deductions';
  static String deductionDetails(String id) => '/hr/deductions/$id';

  // Workplaces
  static const String workplaces = '/hr/workplaces';
  static String workplaceDetails(String id) => '/hr/workplaces/$id';

  // Schedules
  static const String schedules = '/hr/schedules';
  static String scheduleDetails(String id) => '/hr/schedules/$id';

  // Dashboard & Reports
  static const String dashboardMetrics = '/hr/dashboard/metrics';
  static const String reports = '/hr/reports';

  // Notifications & Messages
  static const String notifications = '/hr/notifications';
  static String notificationRead(String id) => '/hr/notifications/$id/read';
  static const String notificationsReadAll = '/hr/notifications/read-all';
  static const String messages = '/hr/messages';

  // Audit Logs
  static const String auditLogs = '/hr/audit-logs';

  // Settings
  static const String settings = '/hr/settings';
}
