import 'dart:ui' show AppLifecycleState;
import '../entities/employee_location.dart';
import '../entities/tracking_enums.dart';

/// Clean Architecture domain repository interface for background & session-based location tracking
abstract class LocationTrackingRepository {
  /// Reactive stream of location updates (single active broadcast)
  Stream<EmployeeLocation> get locationStream;

  /// Returns current operational tracking status
  TrackingStatus get trackingStatus;

  /// Returns active work session ID if tracking is active
  String? get activeWorkSessionId;

  /// Returns the most recent acquired location
  EmployeeLocation? get lastKnownLocation;

  /// Checks current device location permission state
  Future<LocationPermissionState> checkPermissions();

  /// Requests foreground and optionally background location permissions
  Future<LocationPermissionState> requestPermissions({bool requestBackground = true});

  /// Starts work session based location tracking
  /// Must be tied to an authenticated session and active work session
  Future<bool> startTracking({
    required String workSessionId,
    required String employeeId,
    int intervalSeconds = 30,
    int distanceFilterMeters = 10,
  });

  /// Stops location tracking (e.g. upon check-out, logout, or session revoked)
  Future<void> stopTracking({String? reason});

  /// Manually queries current location once
  Future<EmployeeLocation?> getCurrentLocation();

  /// Synchronizes locally queued offline location updates to the backend
  Future<int> syncOfflineLocations();

  /// Retrieves list of un-synced offline location updates
  Future<List<EmployeeLocation>> getQueuedLocations();

  /// Notifies tracking engine of Flutter app lifecycle transitions
  void handleLifecycleChange(AppLifecycleState state);

  /// Disposes resources and cancels streams
  Future<void> dispose();
}
