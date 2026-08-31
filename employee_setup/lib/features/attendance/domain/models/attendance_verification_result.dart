import 'attendance_api_contracts.dart';
import 'device_integrity_result.dart';
import 'location_result.dart';
import 'network_risk_info.dart';

/// Status of the Geofence / Location verification stage.
enum GeofenceVerificationStatus {
  idle,
  checkingLocation,
  insideGeofence,
  outsideGeofence,
  locationPermissionDenied,
  locationServiceDisabled,
  lowLocationAccuracy,
  mockLocationDetected,
  locationError;

  bool get isSuccess => this == GeofenceVerificationStatus.insideGeofence;
  bool get isInProgress => this == GeofenceVerificationStatus.checkingLocation;
  bool get isFailed =>
      this == GeofenceVerificationStatus.outsideGeofence ||
      this == GeofenceVerificationStatus.locationPermissionDenied ||
      this == GeofenceVerificationStatus.locationServiceDisabled ||
      this == GeofenceVerificationStatus.lowLocationAccuracy ||
      this == GeofenceVerificationStatus.mockLocationDetected ||
      this == GeofenceVerificationStatus.locationError;
}

/// Status of the Screen Security & Overlay Detection stage.
enum ScreenSecurityStatus {
  idle,
  checkingScreenSecurity,
  screenSafe,
  screenObscured,
  screenSecurityError;

  bool get isSuccess => this == ScreenSecurityStatus.screenSafe;
  bool get isInProgress => this == ScreenSecurityStatus.checkingScreenSecurity;
  bool get isFailed =>
      this == ScreenSecurityStatus.screenObscured ||
      this == ScreenSecurityStatus.screenSecurityError;
}

/// Status of the Device Biometric Authentication stage.
enum BiometricVerificationStatus {
  idle,
  biometricChecking,
  biometricAvailable,
  biometricAuthenticating,
  biometricSuccess,
  biometricFailed,
  biometricNotEnrolled,
  biometricNotAvailable,
  biometricCancelled,
  biometricLockedOut;

  bool get isSuccess => this == BiometricVerificationStatus.biometricSuccess;
  bool get isInProgress =>
      this == BiometricVerificationStatus.biometricChecking ||
      this == BiometricVerificationStatus.biometricAuthenticating;
  bool get isFailed =>
      this == BiometricVerificationStatus.biometricFailed ||
      this == BiometricVerificationStatus.biometricNotEnrolled ||
      this == BiometricVerificationStatus.biometricNotAvailable ||
      this == BiometricVerificationStatus.biometricCancelled ||
      this == BiometricVerificationStatus.biometricLockedOut;
}

/// Status of the Cloud Authentication & Session stage.
enum CloudAuthenticationStatus {
  idle,
  authSessionChecking,
  authSessionValid,
  authSessionExpired,
  authSessionInvalid,
  authNetworkError;

  bool get isSuccess => this == CloudAuthenticationStatus.authSessionValid;
  bool get isInProgress => this == CloudAuthenticationStatus.authSessionChecking;
  bool get isFailed =>
      this == CloudAuthenticationStatus.authSessionExpired ||
      this == CloudAuthenticationStatus.authSessionInvalid ||
      this == CloudAuthenticationStatus.authNetworkError;
}

/// Status of the Cloud Attendance Registration stage.
enum CloudAttendanceRegistrationStatus {
  idle,
  registering,
  registered,
  offlineQueued,
  rejected,
  failed;

  bool get isSuccess =>
      this == CloudAttendanceRegistrationStatus.registered ||
      this == CloudAttendanceRegistrationStatus.offlineQueued;
  bool get isInProgress =>
      this == CloudAttendanceRegistrationStatus.registering;
  bool get isFailed =>
      this == CloudAttendanceRegistrationStatus.rejected ||
      this == CloudAttendanceRegistrationStatus.failed;
}

/// Domain-level composite result containing the status of each verification stage.
class AttendanceSecurityVerificationResult {
  final GeofenceVerificationStatus geofenceStatus;
  final ScreenSecurityStatus screenSecurityStatus;
  final BiometricVerificationStatus biometricStatus;
  final CloudAuthenticationStatus cloudAuthenticationStatus;
  final CloudAttendanceRegistrationStatus attendanceRegistrationStatus;
  final LocationResult? locationResult;
  final String? biometricToken;
  final DeviceIntegrityResult? integrityResult;
  final NetworkRiskInfo? networkRisk;
  final AttendanceVerificationResponse? response;
  final String? errorMessage;
  final DateTime timestamp;

  const AttendanceSecurityVerificationResult({
    this.geofenceStatus = GeofenceVerificationStatus.idle,
    this.screenSecurityStatus = ScreenSecurityStatus.idle,
    this.biometricStatus = BiometricVerificationStatus.idle,
    this.cloudAuthenticationStatus = CloudAuthenticationStatus.idle,
    this.attendanceRegistrationStatus = CloudAttendanceRegistrationStatus.idle,
    this.locationResult,
    this.biometricToken,
    this.integrityResult,
    this.networkRisk,
    this.response,
    this.errorMessage,
    required this.timestamp,
  });

  bool get isAllLocalChecksSuccessful =>
      geofenceStatus.isSuccess &&
      screenSecurityStatus.isSuccess &&
      biometricStatus.isSuccess &&
      cloudAuthenticationStatus.isSuccess;

  bool get isFullyApproved =>
      isAllLocalChecksSuccessful &&
      attendanceRegistrationStatus == CloudAttendanceRegistrationStatus.registered;

  bool get isPendingHr =>
      attendanceRegistrationStatus == CloudAttendanceRegistrationStatus.offlineQueued;

  bool get isFailed =>
      geofenceStatus.isFailed ||
      screenSecurityStatus.isFailed ||
      biometricStatus.isFailed ||
      cloudAuthenticationStatus.isFailed ||
      attendanceRegistrationStatus.isFailed;

  AttendanceSecurityVerificationResult copyWith({
    GeofenceVerificationStatus? geofenceStatus,
    ScreenSecurityStatus? screenSecurityStatus,
    BiometricVerificationStatus? biometricStatus,
    CloudAuthenticationStatus? cloudAuthenticationStatus,
    CloudAttendanceRegistrationStatus? attendanceRegistrationStatus,
    LocationResult? locationResult,
    String? biometricToken,
    DeviceIntegrityResult? integrityResult,
    NetworkRiskInfo? networkRisk,
    AttendanceVerificationResponse? response,
    String? errorMessage,
    DateTime? timestamp,
  }) {
    return AttendanceSecurityVerificationResult(
      geofenceStatus: geofenceStatus ?? this.geofenceStatus,
      screenSecurityStatus: screenSecurityStatus ?? this.screenSecurityStatus,
      biometricStatus: biometricStatus ?? this.biometricStatus,
      cloudAuthenticationStatus:
          cloudAuthenticationStatus ?? this.cloudAuthenticationStatus,
      attendanceRegistrationStatus:
          attendanceRegistrationStatus ?? this.attendanceRegistrationStatus,
      locationResult: locationResult ?? this.locationResult,
      biometricToken: biometricToken ?? this.biometricToken,
      integrityResult: integrityResult ?? this.integrityResult,
      networkRisk: networkRisk ?? this.networkRisk,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
