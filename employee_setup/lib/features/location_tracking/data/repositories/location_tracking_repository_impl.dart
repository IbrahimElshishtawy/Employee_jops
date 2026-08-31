import 'dart:async';
import 'dart:ui' show AppLifecycleState;
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/utils/secure_logger.dart';
import '../../domain/entities/employee_location.dart';
import '../../domain/entities/tracking_enums.dart';
import '../../domain/repositories/location_tracking_repository.dart';
import '../datasources/location_local_data_source.dart';
import '../datasources/location_platform_data_source.dart';
import '../datasources/location_remote_data_source.dart';

class LocationTrackingRepositoryImpl implements LocationTrackingRepository {
  final LocationPlatformDataSource platformDataSource;
  final LocationLocalDataSource localDataSource;
  final LocationRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  final StreamController<EmployeeLocation> _locationStreamController =
      StreamController<EmployeeLocation>.broadcast();

  StreamSubscription<EmployeeLocation>? _rawPositionSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  TrackingStatus _trackingStatus = TrackingStatus.stopped;
  String? _activeWorkSessionId;
  String? _activeEmployeeId;
  EmployeeLocation? _lastKnownLocation;
  bool _isBackgroundMode = false;
  int _intervalSeconds = 30;
  int _distanceFilterMeters = 10;

  LocationTrackingRepositoryImpl({
    required this.platformDataSource,
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityService,
  }) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncOfflineLocations();
      }
    });
  }

  @override
  Stream<EmployeeLocation> get locationStream => _locationStreamController.stream;

  @override
  TrackingStatus get trackingStatus => _trackingStatus;

  @override
  String? get activeWorkSessionId => _activeWorkSessionId;

  @override
  EmployeeLocation? get lastKnownLocation => _lastKnownLocation;

  @override
  Future<LocationPermissionState> checkPermissions() async {
    return await _platformDataSource.checkPermission();
  }

  @override
  Future<LocationPermissionState> requestPermissions({bool requestBackground = true}) async {
    return await _platformDataSource.requestPermission(requestBackground: requestBackground);
  }

  @override
  Future<bool> startTracking({
    required String workSessionId,
    required String employeeId,
    int intervalSeconds = 30,
    int distanceFilterMeters = 10,
  }) async {
    // 1. Prevent duplicate start if already tracking the same session
    if (_trackingStatus.isTracking && _activeWorkSessionId == workSessionId) {
      SecureLogger.info('LocationTrackingRepo', 'Tracking already active for session $workSessionId');
      return true;
    }

    // Stop any existing tracking cleanly first
    if (_trackingStatus.isTracking) {
      await stopTracking(reason: 'Switching work session');
    }

    // 2. Validate permission
    final perm = await checkPermissions();
    if (!perm.hasForegroundAccess) {
      _trackingStatus = TrackingStatus.error;
      SecureLogger.warn('LocationTrackingRepo', 'Cannot start tracking: insufficient permission $perm');
      return false;
    }

    _activeWorkSessionId = workSessionId;
    _activeEmployeeId = employeeId;
    _intervalSeconds = intervalSeconds;
    _distanceFilterMeters = distanceFilterMeters;
    _trackingStatus = _isBackgroundMode
        ? TrackingStatus.activeBackground
        : TrackingStatus.activeForeground;

    // 3. Obtain initial location snapshot
    final initialPos = await _platformDataSource.getCurrentPosition();
    if (initialPos != null) {
      final enrichedLocation = initialPos.copyWith(
        workSessionId: _activeWorkSessionId,
        employeeId: _activeEmployeeId,
      );
      _handleNewLocation(enrichedLocation);
    }

    // 4. Subscribe to platform stream (single active subscription)
    _startPositionStream();

    SecureLogger.info(
      'LocationTrackingRepo',
      'Location tracking started for session $workSessionId (Interval: ${intervalSeconds}s, Filter: ${distanceFilterMeters}m)',
    );
    return true;
  }

  void _startPositionStream() {
    _rawPositionSubscription?.cancel();
    _rawPositionSubscription = _platformDataSource
        .getPositionStream(
          intervalSeconds: _intervalSeconds,
          distanceFilterMeters: _distanceFilterMeters,
        )
        .listen(
          (loc) {
            final enriched = loc.copyWith(
              workSessionId: _activeWorkSessionId,
              employeeId: _activeEmployeeId,
              source: _isBackgroundMode ? LocationSource.background : LocationSource.foreground,
            );
            _handleNewLocation(enriched);
          },
          onError: (error) {
            SecureLogger.error('LocationTrackingRepo', 'Position stream error', error);
            _trackingStatus = TrackingStatus.error;
          },
          cancelOnError: false,
        );
  }

  Future<void> _handleNewLocation(EmployeeLocation location) async {
    _lastKnownLocation = location;
    if (!_locationStreamController.isClosed) {
      _locationStreamController.add(location);
    }

    // Attempt remote synchronization
    final isOnline = await _connectivityService.isConnected;
    if (isOnline) {
      final synced = await _remoteDataSource.syncLocation(location);
      if (!synced) {
        await _localDataSource.enqueueLocation(location);
      }
    } else {
      await _localDataSource.enqueueLocation(location);
    }
  }

  @override
  Future<void> stopTracking({String? reason}) async {
    if (_trackingStatus == TrackingStatus.stopped) return;

    SecureLogger.info(
      'LocationTrackingRepo',
      'Stopping location tracking. Reason: ${reason ?? "Requested by user/system"}',
    );

    await _rawPositionSubscription?.cancel();
    _rawPositionSubscription = null;

    _trackingStatus = TrackingStatus.stopped;
    _activeWorkSessionId = null;
    _activeEmployeeId = null;

    // Flush any pending queue if online
    syncOfflineLocations();
  }

  @override
  Future<EmployeeLocation?> getCurrentLocation() async {
    final pos = await _platformDataSource.getCurrentPosition();
    if (pos != null) {
      final enriched = pos.copyWith(
        workSessionId: _activeWorkSessionId,
        employeeId: _activeEmployeeId,
      );
      _lastKnownLocation = enriched;
      return enriched;
    }
    return _lastKnownLocation;
  }

  @override
  Future<int> syncOfflineLocations() async {
    try {
      final isOnline = await _connectivityService.isConnected;
      if (!isOnline) return 0;

      final queued = await _localDataSource.getQueuedLocations();
      if (queued.isEmpty) return 0;

      final success = await _remoteDataSource.syncLocationBatch(queued);
      if (success) {
        await _localDataSource.removeLocations(queued);
        SecureLogger.info('LocationTrackingRepo', 'Successfully synced ${queued.length} offline locations');
        return queued.length;
      }
      return 0;
    } catch (e) {
      SecureLogger.error('LocationTrackingRepo', 'syncOfflineLocations error', e);
      return 0;
    }
  }

  @override
  Future<List<EmployeeLocation>> getQueuedLocations() async {
    return await _localDataSource.getQueuedLocations();
  }

  @override
  void handleLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isBackgroundMode = false;
        if (_trackingStatus.isTracking) {
          _trackingStatus = TrackingStatus.activeForeground;
        }
        // Sync any buffered locations when returning to foreground
        syncOfflineLocations();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _isBackgroundMode = true;
        if (_trackingStatus.isTracking) {
          _trackingStatus = TrackingStatus.activeBackground;
        }
        break;

      case AppLifecycleState.detached:
        // App terminating — stop tracking cleanly
        stopTracking(reason: 'App terminated');
        break;
    }
  }

  @override
  Future<void> dispose() async {
    await stopTracking(reason: 'Disposing repository');
    await _connectivitySubscription?.cancel();
    await _locationStreamController.close();
  }
}
