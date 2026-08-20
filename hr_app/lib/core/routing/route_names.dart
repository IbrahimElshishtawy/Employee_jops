/// Named route definitions for CyberWise IE HR Portal
class RouteNames {
  RouteNames._();

  static const String login = '/login';
  static const String unauthorized = '/unauthorized';
  static const String notFound = '/not-found';

  // Authenticated Shell Routes
  static const String dashboard = '/dashboard';
  static const String employees = '/employees';
  static const String employeeDetails = '/employees/:id';
  static const String employeeNew = '/employees/new';

  static const String attendance = '/attendance';
  static const String requests = '/requests';
  static const String requestDetails = '/requests/:id';

  static const String advances = '/advances';
  static const String advanceDetails = '/advances/:id';

  static const String deductions = '/deductions';
  static const String workplaces = '/workplaces';
  static const String schedules = '/schedules';
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String messages = '/messages';
  static const String auditLogs = '/audit-logs';
  static const String settings = '/settings';
}
