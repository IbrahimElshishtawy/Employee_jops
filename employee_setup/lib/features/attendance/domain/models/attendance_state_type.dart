/// Comprehensive enum of all 22 distinct attendance lifecycle and system states.
enum AttendanceStateType {
  notStarted,
  beforeShift,
  readyForCheckIn,
  checkingLocation,
  locationValid,
  locationInvalid,
  biometricRequired,
  verifyingBiometric,
  checkingIn,
  checkedIn,
  readyForCheckOut,
  checkingOut,
  checkedOut,
  workdayCompleted,
  outsideWorkplace,
  locationPermissionRequired,
  locationServiceDisabled,
  locationUnavailable,
  biometricUnavailable,
  biometricFailed,
  offlinePendingSync,
  error;

  bool get isLoading =>
      this == AttendanceStateType.checkingLocation ||
      this == AttendanceStateType.verifyingBiometric ||
      this == AttendanceStateType.checkingIn ||
      this == AttendanceStateType.checkingOut;

  bool get isCheckedIn =>
      this == AttendanceStateType.checkedIn ||
      this == AttendanceStateType.readyForCheckOut ||
      this == AttendanceStateType.checkingOut;

  bool get isCompleted =>
      this == AttendanceStateType.checkedOut ||
      this == AttendanceStateType.workdayCompleted;
}
