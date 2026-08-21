import '../../domain/entities/settings_entity.dart';

/// Mock Settings Repository seeded with default production values
class MockSettingsRepository implements SettingsRepository {
  SystemSettingsBundle _bundle = const SystemSettingsBundle(
    company: CompanySettingsEntity(
      companyName: 'CyberWise IE',
      supportEmail: 'hr@cyberwise.com',
      timezone: 'Africa/Cairo (UTC+2)',
      currency: 'EGP (Egyptian Pound)',
      fiscalYearStart: 'January 1',
    ),
    attendance: AttendancePolicySettingsEntity(
      defaultGracePeriodMinutes: 15,
      maxGpsAccuracyMeters: 50,
      maxDailyOvertimeHours: 4.0,
      autoCheckoutBufferHours: 2,
    ),
    notifications: NotificationSettingsEntity(
      pushNotificationsEnabled: true,
      emailDigestEnabled: true,
      advanceAlertThresholdDays: 3,
      alertSupervisorsOnLateArrival: true,
    ),
    security: SecuritySettingsEntity(
      sessionTimeoutMinutes: 60,
      maxFailedLoginAttempts: 5,
      refreshTokenRotationEnabled: true,
      geofenceTamperDetectionEnabled: true,
    ),
  );

  @override
  Future<SystemSettingsBundle> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _bundle;
  }

  @override
  Future<CompanySettingsEntity> updateCompanySettings(CompanySettingsEntity settings) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bundle = _bundle.copyWith(company: settings);
    return settings;
  }

  @override
  Future<AttendancePolicySettingsEntity> updateAttendancePolicySettings(AttendancePolicySettingsEntity settings) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bundle = _bundle.copyWith(attendance: settings);
    return settings;
  }

  @override
  Future<NotificationSettingsEntity> updateNotificationSettings(NotificationSettingsEntity settings) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bundle = _bundle.copyWith(notifications: settings);
    return settings;
  }

  @override
  Future<SecuritySettingsEntity> updateSecuritySettings(SecuritySettingsEntity settings) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bundle = _bundle.copyWith(security: settings);
    return settings;
  }
}
