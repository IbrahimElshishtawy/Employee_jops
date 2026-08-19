/// Comprehensive enum of all attendance lifecycle, verification, and failure states.
enum AttendanceStateType {
  notStarted,
  beforeShift,
  readyForCheckIn,
  checkingLocation,
  verifyingLocation,
  locationValid,
  locationInvalid,
  biometricRequired,
  verifyingBiometric,
  verifyingDevice,
  checkingIn,
  submitting,
  checkedIn,
  readyForCheckOut,
  checkingOut,
  checkedOut,
  workdayCompleted,
  outsideWorkplace,
  locationPermissionRequired,
  locationPermissionDenied,
  locationServiceDisabled,
  locationUnavailable,
  lowLocationAccuracy,
  mockLocationDetected,
  biometricUnavailable,
  biometricFailed,
  deviceIntegrityFailed,
  workScheduleInvalid,
  alreadyCheckedIn,
  alreadyCheckedOut,
  networkError,
  serverRejected,
  offlinePendingSync,
  error;

  bool get isLoading =>
      this == AttendanceStateType.checkingLocation ||
      this == AttendanceStateType.verifyingLocation ||
      this == AttendanceStateType.verifyingBiometric ||
      this == AttendanceStateType.verifyingDevice ||
      this == AttendanceStateType.checkingIn ||
      this == AttendanceStateType.checkingOut ||
      this == AttendanceStateType.submitting;

  bool get isCheckedIn =>
      this == AttendanceStateType.checkedIn ||
      this == AttendanceStateType.readyForCheckOut ||
      this == AttendanceStateType.checkingOut;

  bool get isCompleted =>
      this == AttendanceStateType.checkedOut ||
      this == AttendanceStateType.workdayCompleted;

  bool get isFailure =>
      this == AttendanceStateType.locationPermissionDenied ||
      this == AttendanceStateType.locationServiceDisabled ||
      this == AttendanceStateType.lowLocationAccuracy ||
      this == AttendanceStateType.outsideWorkplace ||
      this == AttendanceStateType.mockLocationDetected ||
      this == AttendanceStateType.biometricFailed ||
      this == AttendanceStateType.deviceIntegrityFailed ||
      this == AttendanceStateType.workScheduleInvalid ||
      this == AttendanceStateType.alreadyCheckedIn ||
      this == AttendanceStateType.alreadyCheckedOut ||
      this == AttendanceStateType.networkError ||
      this == AttendanceStateType.serverRejected ||
      this == AttendanceStateType.error;
}
