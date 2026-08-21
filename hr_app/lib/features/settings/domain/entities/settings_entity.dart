/// Company & General Organization Settings
class CompanySettingsEntity {
  final String companyName;
  final String supportEmail;
  final String timezone;
  final String currency;
  final String fiscalYearStart;

  const CompanySettingsEntity({
    required this.companyName,
    required this.supportEmail,
    required this.timezone,
    required this.currency,
    required this.fiscalYearStart,
  });

  CompanySettingsEntity copyWith({
    String? companyName,
    String? supportEmail,
    String? timezone,
    String? currency,
    String? fiscalYearStart,
  }) {
    return CompanySettingsEntity(
      companyName: companyName ?? this.companyName,
      supportEmail: supportEmail ?? this.supportEmail,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      fiscalYearStart: fiscalYearStart ?? this.fiscalYearStart,
    );
  }
}

/// Global Attendance Policy Settings
class AttendancePolicySettingsEntity {
  final int defaultGracePeriodMinutes;
  final int maxGpsAccuracyMeters;
  final double maxDailyOvertimeHours;
  final int autoCheckoutBufferHours;

  const AttendancePolicySettingsEntity({
    required this.defaultGracePeriodMinutes,
    required this.maxGpsAccuracyMeters,
    required this.maxDailyOvertimeHours,
    required this.autoCheckoutBufferHours,
  });

  AttendancePolicySettingsEntity copyWith({
    int? defaultGracePeriodMinutes,
    int? maxGpsAccuracyMeters,
    double? maxDailyOvertimeHours,
    int? autoCheckoutBufferHours,
  }) {
    return AttendancePolicySettingsEntity(
      defaultGracePeriodMinutes: defaultGracePeriodMinutes ?? this.defaultGracePeriodMinutes,
      maxGpsAccuracyMeters: maxGpsAccuracyMeters ?? this.maxGpsAccuracyMeters,
      maxDailyOvertimeHours: maxDailyOvertimeHours ?? this.maxDailyOvertimeHours,
      autoCheckoutBufferHours: autoCheckoutBufferHours ?? this.autoCheckoutBufferHours,
    );
  }
}

/// System-Wide Notification Rule Settings
class NotificationSettingsEntity {
  final bool pushNotificationsEnabled;
  final bool emailDigestEnabled;
  final int advanceAlertThresholdDays;
  final bool alertSupervisorsOnLateArrival;

  const NotificationSettingsEntity({
    required this.pushNotificationsEnabled,
    required this.emailDigestEnabled,
    required this.advanceAlertThresholdDays,
    required this.alertSupervisorsOnLateArrival,
  });

  NotificationSettingsEntity copyWith({
    bool? pushNotificationsEnabled,
    bool? emailDigestEnabled,
    int? advanceAlertThresholdDays,
    bool? alertSupervisorsOnLateArrival,
  }) {
    return NotificationSettingsEntity(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailDigestEnabled: emailDigestEnabled ?? this.emailDigestEnabled,
      advanceAlertThresholdDays: advanceAlertThresholdDays ?? this.advanceAlertThresholdDays,
      alertSupervisorsOnLateArrival: alertSupervisorsOnLateArrival ?? this.alertSupervisorsOnLateArrival,
    );
  }
}

/// High-Privilege Security & Session Policy Settings
class SecuritySettingsEntity {
  final int sessionTimeoutMinutes;
  final int maxFailedLoginAttempts;
  final bool refreshTokenRotationEnabled;
  final bool geofenceTamperDetectionEnabled;

  const SecuritySettingsEntity({
    required this.sessionTimeoutMinutes,
    required this.maxFailedLoginAttempts,
    required this.refreshTokenRotationEnabled,
    required this.geofenceTamperDetectionEnabled,
  });

  SecuritySettingsEntity copyWith({
    int? sessionTimeoutMinutes,
    int? maxFailedLoginAttempts,
    bool? refreshTokenRotationEnabled,
    bool? geofenceTamperDetectionEnabled,
  }) {
    return SecuritySettingsEntity(
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      maxFailedLoginAttempts: maxFailedLoginAttempts ?? this.maxFailedLoginAttempts,
      refreshTokenRotationEnabled: refreshTokenRotationEnabled ?? this.refreshTokenRotationEnabled,
      geofenceTamperDetectionEnabled: geofenceTamperDetectionEnabled ?? this.geofenceTamperDetectionEnabled,
    );
  }
}

/// Bundle containing all runtime settings
class SystemSettingsBundle {
  final CompanySettingsEntity company;
  final AttendancePolicySettingsEntity attendance;
  final NotificationSettingsEntity notifications;
  final SecuritySettingsEntity security;

  const SystemSettingsBundle({
    required this.company,
    required this.attendance,
    required this.notifications,
    required this.security,
  });

  SystemSettingsBundle copyWith({
    CompanySettingsEntity? company,
    AttendancePolicySettingsEntity? attendance,
    NotificationSettingsEntity? notifications,
    SecuritySettingsEntity? security,
  }) {
    return SystemSettingsBundle(
      company: company ?? this.company,
      attendance: attendance ?? this.attendance,
      notifications: notifications ?? this.notifications,
      security: security ?? this.security,
    );
  }
}

abstract class SettingsRepository {
  Future<SystemSettingsBundle> getSettings();
  Future<CompanySettingsEntity> updateCompanySettings(CompanySettingsEntity settings);
  Future<AttendancePolicySettingsEntity> updateAttendancePolicySettings(AttendancePolicySettingsEntity settings);
  Future<NotificationSettingsEntity> updateNotificationSettings(NotificationSettingsEntity settings);
  Future<SecuritySettingsEntity> updateSecuritySettings(SecuritySettingsEntity settings);
}
