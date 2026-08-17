class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';

  // Shell Tabs
  static const String home = '/home';
  static const String requests = '/requests';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  // Attendance
  static const String attendanceHistory = '/attendance/history';

  // Advances
  static const String advances = '/requests/advances';
  static const String newAdvance = '/requests/advances/new';
  static const String advanceDetails = '/requests/advances/:id';
  static const String expenseReport = '/requests/advances/:id/report';

  // Permissions
  static const String permissions = '/requests/permissions';
  static const String newPermission = '/requests/permissions/new';
  static const String permissionDetails = '/requests/permissions/:id';

  // Vacations
  static const String vacations = '/requests/vacations';
  static const String newVacation = '/requests/vacations/new';
  static const String vacationDetails = '/requests/vacations/:id';

  // Notifications Details
  static const String notificationDetails = '/notifications/:id';

  // Settings
  static const String settings = '/settings';
  static const String developerDemo = '/settings/demo';
}
