/// Lightweight feature toggle configuration
class FeatureFlags {
  FeatureFlags._();

  static bool enableReportsExport = true;
  static bool enableAuditLogs = true;
  static bool enableAdvancedAttendanceFilters = true;
  static bool enableNotificationsSound = false;
  static bool enableRealtimeWebsockets = false;
}
