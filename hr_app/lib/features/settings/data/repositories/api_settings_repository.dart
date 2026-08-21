import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/settings_entity.dart';

/// Live Production Settings Repository
class ApiSettingsRepository implements SettingsRepository {
  final ApiClient _apiClient;

  ApiSettingsRepository(this._apiClient);

  @override
  Future<SystemSettingsBundle> getSettings() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.settings,
        parser: (data) => _mapBundle(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<CompanySettingsEntity> updateCompanySettings(CompanySettingsEntity settings) async {
    try {
      final response = await _apiClient.patch(
        '${ApiEndpoints.settings}/company',
        body: {
          'companyName': settings.companyName,
          'supportEmail': settings.supportEmail,
          'timezone': settings.timezone,
          'currency': settings.currency,
          'fiscalYearStart': settings.fiscalYearStart,
        },
        parser: (data) => _mapCompany(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AttendancePolicySettingsEntity> updateAttendancePolicySettings(AttendancePolicySettingsEntity settings) async {
    try {
      final response = await _apiClient.patch(
        '${ApiEndpoints.settings}/attendance-policy',
        body: {
          'defaultGracePeriodMinutes': settings.defaultGracePeriodMinutes,
          'maxGpsAccuracyMeters': settings.maxGpsAccuracyMeters,
          'maxDailyOvertimeHours': settings.maxDailyOvertimeHours,
          'autoCheckoutBufferHours': settings.autoCheckoutBufferHours,
        },
        parser: (data) => _mapAttendance(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<NotificationSettingsEntity> updateNotificationSettings(NotificationSettingsEntity settings) async {
    try {
      final response = await _apiClient.patch(
        '${ApiEndpoints.settings}/notifications',
        body: {
          'pushNotificationsEnabled': settings.pushNotificationsEnabled,
          'emailDigestEnabled': settings.emailDigestEnabled,
          'advanceAlertThresholdDays': settings.advanceAlertThresholdDays,
          'alertSupervisorsOnLateArrival': settings.alertSupervisorsOnLateArrival,
        },
        parser: (data) => _mapNotifications(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  @override
  Future<SecuritySettingsEntity> updateSecuritySettings(SecuritySettingsEntity settings) async {
    try {
      final response = await _apiClient.patch(
        '${ApiEndpoints.settings}/security',
        body: {
          'sessionTimeoutMinutes': settings.sessionTimeoutMinutes,
          'maxFailedLoginAttempts': settings.maxFailedLoginAttempts,
          'refreshTokenRotationEnabled': settings.refreshTokenRotationEnabled,
          'geofenceTamperDetectionEnabled': settings.geofenceTamperDetectionEnabled,
        },
        parser: (data) => _mapSecurity(data as Map<String, dynamic>),
      );
      return response.data!;
    } catch (e) {
      throw ErrorHandler.mapExceptionToFailure(e);
    }
  }

  static SystemSettingsBundle _mapBundle(Map<String, dynamic> map) {
    return SystemSettingsBundle(
      company: _mapCompany((map['company'] as Map<String, dynamic>?) ?? {}),
      attendance: _mapAttendance((map['attendance'] as Map<String, dynamic>?) ?? {}),
      notifications: _mapNotifications((map['notifications'] as Map<String, dynamic>?) ?? {}),
      security: _mapSecurity((map['security'] as Map<String, dynamic>?) ?? {}),
    );
  }

  static CompanySettingsEntity _mapCompany(Map<String, dynamic> map) {
    return CompanySettingsEntity(
      companyName: map['companyName'] as String? ?? 'CyberWise IE',
      supportEmail: map['supportEmail'] as String? ?? 'hr@cyberwise.com',
      timezone: map['timezone'] as String? ?? 'Africa/Cairo (UTC+2)',
      currency: map['currency'] as String? ?? 'EGP (Egyptian Pound)',
      fiscalYearStart: map['fiscalYearStart'] as String? ?? 'January 1',
    );
  }

  static AttendancePolicySettingsEntity _mapAttendance(Map<String, dynamic> map) {
    return AttendancePolicySettingsEntity(
      defaultGracePeriodMinutes: map['defaultGracePeriodMinutes'] as int? ?? 15,
      maxGpsAccuracyMeters: map['maxGpsAccuracyMeters'] as int? ?? 50,
      maxDailyOvertimeHours: (map['maxDailyOvertimeHours'] as num?)?.toDouble() ?? 4.0,
      autoCheckoutBufferHours: map['autoCheckoutBufferHours'] as int? ?? 2,
    );
  }

  static NotificationSettingsEntity _mapNotifications(Map<String, dynamic> map) {
    return NotificationSettingsEntity(
      pushNotificationsEnabled: map['pushNotificationsEnabled'] as bool? ?? true,
      emailDigestEnabled: map['emailDigestEnabled'] as bool? ?? true,
      advanceAlertThresholdDays: map['advanceAlertThresholdDays'] as int? ?? 3,
      alertSupervisorsOnLateArrival: map['alertSupervisorsOnLateArrival'] as bool? ?? true,
    );
  }

  static SecuritySettingsEntity _mapSecurity(Map<String, dynamic> map) {
    return SecuritySettingsEntity(
      sessionTimeoutMinutes: map['sessionTimeoutMinutes'] as int? ?? 60,
      maxFailedLoginAttempts: map['maxFailedLoginAttempts'] as int? ?? 5,
      refreshTokenRotationEnabled: map['refreshTokenRotationEnabled'] as bool? ?? true,
      geofenceTamperDetectionEnabled: map['geofenceTamperDetectionEnabled'] as bool? ?? true,
    );
  }
}
