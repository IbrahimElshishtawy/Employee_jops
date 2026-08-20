/// Granular Permissions defining access controls in CyberWise IE HR Portal
enum AppPermission {
  // Employees
  employeesRead('employees.read', 'View employee records'),
  employeesCreate('employees.create', 'Create new employees'),
  employeesUpdate('employees.update', 'Modify employee records'),
  employeesDelete('employees.delete', 'Deactivate/Delete employee records'),

  // Attendance
  attendanceRead('attendance.read', 'View attendance logs'),
  attendanceExport('attendance.export', 'Export attendance reports'),

  // Requests
  requestsRead('requests.read', 'View requests'),
  requestsApprove('requests.approve', 'Approve employee requests'),
  requestsReject('requests.reject', 'Reject employee requests'),

  // Advances
  advancesRead('advances.read', 'View salary advances'),
  advancesApprove('advances.approve', 'Approve salary advances'),

  // Deductions
  deductionsRead('deductions.read', 'View deductions'),
  deductionsCreate('deductions.create', 'Create deductions'),

  // Workplaces
  workplacesRead('workplaces.read', 'View workplaces'),
  workplacesCreate('workplaces.create', 'Create workplaces'),
  workplacesUpdate('workplaces.update', 'Modify workplaces'),

  // Schedules
  schedulesRead('schedules.read', 'View work schedules'),
  schedulesCreate('schedules.create', 'Create work schedules'),
  schedulesUpdate('schedules.update', 'Modify work schedules'),

  // Reports
  reportsRead('reports.read', 'View analytics & reports'),
  reportsExport('reports.export', 'Export operational reports'),

  // Notifications & Messages
  notificationsManage('notifications.manage', 'Send HR notifications'),
  messagesManage('messages.manage', 'Send HR messages'),

  // Audit Logs
  auditLogsRead('audit_logs.read', 'Inspect audit trail'),

  // Settings & Roles
  settingsManage('settings.manage', 'Modify system settings and permissions');

  final String key;
  final String description;

  const AppPermission(this.key, this.description);

  static AppPermission? fromKey(String key) {
    for (final p in AppPermission.values) {
      if (p.key == key) return p;
    }
    return null;
  }
}
