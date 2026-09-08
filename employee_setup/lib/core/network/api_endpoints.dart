/// Authoritative API Endpoints Catalog for Employee Mobile Application.
/// Fully matches EMPLOYEE_APP_API_ENDPOINTS.md and backend NestJS Fastify routing.
class ApiEndpoints {
  ApiEndpoints._();

  // 01. App Bootstrap & Health
  static const String healthLive = '/health/live';
  static const String publicSettings = '/settings/public';

  // 02. Authentication & Security
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';
  static const String authMe = '/auth/me';

  // 03. Profile & Onboarding
  static const String employeeMe = '/employees/me';
  static const String updateProfile = '/employees/me/profile';
  static const String workplaceMe = '/employees/me/workplace';
  static const String scheduleMe = '/employees/me/schedule';

  // 04. Workplaces & Geofences
  static const String workplaces = '/workplaces';
  static String workplaceById(String id) => '/workplaces/$id';

  // 05. Schedules & Shifts
  static const String schedules = '/schedules';
  static String scheduleById(String id) => '/schedules/$id';
  static String reportingTree(String id) => '/organization/reporting-tree/$id';

  // 06. Attendance & Smart Punch
  static const String attendanceCheckIn = '/attendance/check-in';
  static const String attendanceCheckOut = '/attendance/check-out';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceMe = '/attendance/me';
  static const String attendanceHistory = '/attendance/me';

  // 07. Requests & Leaves
  static const String requests = '/requests';
  static const String myRequests = '/requests/me';
  static const String leaveBalances = '/requests/leave-balances/me';
  static String requestById(String id) => '/requests/$id';
  static String cancelRequest(String id) => '/requests/$id/cancel';

  // 08. Payroll, Advances & Payslips
  static const String salaryMe = '/payroll/salary/me';
  static const String advances = '/payroll/advances';
  static const String myAdvances = '/payroll/advances/me';
  static String advanceById(String id) => '/payroll/advances/$id';
  static const String myDeductions = '/payroll/deductions/me';
  static const String myPayroll = '/payroll/me';
  static String payrollRecordById(String id) => '/payroll/records/$id';

  // 09. Tasks & Checklist Management
  static const String myTasks = '/tasks/my';
  static String taskById(String id) => '/tasks/$id';
  static String updateTask(String id) => '/tasks/$id';
  static String acceptTask(String id) => '/tasks/$id/accept';
  static String updateTaskStatus(String id) => '/tasks/$id/status';
  static String addTaskChecklist(String id) => '/tasks/$id/checklist';
  static String toggleChecklistItem(String taskId, String itemId) =>
      '/tasks/$taskId/checklist/$itemId';
  static String deleteChecklistItem(String taskId, String itemId) =>
      '/tasks/$taskId/checklist/$itemId';
  static String taskComments(String id) => '/tasks/$id/comments';
  static String taskAttachments(String id) => '/tasks/$id/attachments';
  static String taskHistory(String id) => '/tasks/$id/history';

  // 10. Push Notifications & In-App Alerts
  static const String deviceToken = '/notifications/device-token';
  static String deleteDeviceToken(String token) =>
      '/notifications/device-token/$token';
  static const String notifications = '/notifications';
  static const String unreadNotificationsCount =
      '/notifications/unread-count';
  static String markNotificationRead(String id) =>
      '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String notificationPreferences = '/notifications/preferences';

  // 11. HR Announcements
  static const String announcements = '/announcements';
  static String announcementById(String id) => '/announcements/$id';
  static String readAnnouncement(String id) => '/announcements/$id/read';

  // 12. Internal Messaging & Chat
  static const String conversations = '/messages/conversations';
  static const String groupConversations = '/messages/groups';
  static const String unreadMessagesCount = '/messages/unread-count';
  static String conversationById(String id) => '/messages/conversations/$id';
  static String conversationMessages(String id) =>
      '/messages/conversations/$id/messages';
  static String readConversation(String id) =>
      '/messages/conversations/$id/read';
  static String deleteMessage(String id) => '/messages/$id';

  // 13. Service Requests
  static const String serviceRequests = '/service-requests';
  static String serviceRequestById(String id) => '/service-requests/$id';
  static String startServiceRequest(String id) => '/service-requests/$id/start';
  static String completeServiceRequest(String id) =>
      '/service-requests/$id/complete';
  static String reviewServiceRequest(String id) =>
      '/service-requests/$id/review';
  static String cancelServiceRequest(String id) =>
      '/service-requests/$id/cancel';
  static String serviceRequestComments(String id) =>
      '/service-requests/$id/comments';

  // 14. Shift Handover
  static const String handover = '/handover';
  static String handoverById(String id) => '/handover/$id';
  static String acknowledgeHandover(String id) => '/handover/$id/acknowledge';
  static String addHandoverItem(String id) => '/handover/$id/items';

  // 15. Employee Self-Reports
  static const String reportsMe = '/reports/me';

  // 16. Incidents & Safety Reporting
  static const String incidents = '/incidents';
  static String incidentById(String id) => '/incidents/$id';

  // 17. Maintenance Requests
  static const String maintenanceRequests = '/maintenance/requests';
  static String maintenanceRequestById(String id) =>
      '/maintenance/requests/$id';

  // 18. Lost & Found
  static const String lostFound = '/lost-found';
  static String lostFoundById(String id) => '/lost-found/$id';

  // 19. Employee Documents
  static const String documents = '/documents';
  static String documentById(String id) => '/documents/$id';

  // 20. Performance Goals & Reviews
  static const String performanceGoals = '/performance/goals';
  static String updateGoalProgress(String id) =>
      '/performance/goals/$id/progress';
  static const String performanceReviews = '/performance/reviews';
  static String acknowledgeReview(String id) =>
      '/performance/reviews/$id/acknowledge';

  // 21. Training & Certificates
  static const String trainingCourses = '/training/courses';
  static const String trainingSessions = '/training/sessions';
  static const String trainingCertificates = '/training/certificates';

  // 22. Sessions & Active Devices
  static const String registerSession = '/sessions/register';
  static const String myDevices = '/sessions/my-devices';
  static String sessionById(String id) => '/sessions/$id';
  static String terminateOtherSessions(String currentSessionId) =>
      '/sessions/other/$currentSessionId';

  // 23. Offline Sync Engine
  static const String sync = '/sync';
  static const String syncBatch = '/sync/batch';
  static const String syncChanges = '/sync/changes';
  static const String syncQueue = '/sync/queue';
  static String syncRetry(String id) => '/sync/retry/$id';
  static String syncResolveConflict(String id) => '/sync/resolve-conflict/$id';

  // 24. File Storage & Attachments
  static const String storageUpload = '/storage/upload';
  static String storageMetadata(String folder, String filename) =>
      '/storage/metadata/$folder/$filename';
}
