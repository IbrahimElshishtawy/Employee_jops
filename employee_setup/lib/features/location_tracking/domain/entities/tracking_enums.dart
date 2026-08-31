/// Standardized location permission states
enum LocationPermissionState {
  notDetermined,
  foregroundGranted,
  backgroundGranted,
  denied,
  permanentlyDenied,
  serviceDisabled;

  bool get hasForegroundAccess =>
      this == LocationPermissionState.foregroundGranted ||
      this == LocationPermissionState.backgroundGranted;

  bool get hasBackgroundAccess =>
      this == LocationPermissionState.backgroundGranted;

  bool get isDenied =>
      this == LocationPermissionState.denied ||
      this == LocationPermissionState.permanentlyDenied;
}

/// Operational state of the location tracking engine
enum TrackingStatus {
  stopped,
  starting,
  activeForeground,
  activeBackground,
  paused,
  error;

  bool get isTracking =>
      this == TrackingStatus.activeForeground ||
      this == TrackingStatus.activeBackground;

  bool get isBackground => this == TrackingStatus.activeBackground;
}

/// Location sync status with backend
enum LocationSyncStatus {
  idle,
  syncing,
  synced,
  queuedOffline,
  error;
}
