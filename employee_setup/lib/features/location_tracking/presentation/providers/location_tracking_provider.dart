import 'dart:async';
import 'dart:ui' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../domain/entities/employee_location.dart';
import '../../domain/entities/tracking_enums.dart';
import '../../domain/repositories/location_tracking_repository.dart';
import '../../data/datasources/location_local_data_source.dart';
import '../../data/datasources/location_platform_data_source.dart';
import '../../data/datasources/mock_location_platform_data_source.dart';
import '../../data/datasources/location_remote_data_source.dart';
import '../../data/repositories/location_tracking_repository_impl.dart';

// ─── Location Tracking Infrastructure Providers ──────────────────────

final mockLocationPlatformDataSourceProvider = Provider<MockLocationPlatformDataSource>((ref) {
  return MockLocationPlatformDataSource();
});

final realLocationPlatformDataSourceProvider = Provider<LocationPlatformDataSource>((ref) {
  return GeolocatorLocationPlatformDataSource();
});

final locationPlatformDataSourceProvider = Provider<LocationPlatformDataSource>((ref) {
  final demo = ref.watch(demoControlsProvider);
  if (!demo.useRealDeviceSensors) {
    return ref.watch(mockLocationPlatformDataSourceProvider);
  }
  return ref.watch(realLocationPlatformDataSourceProvider);
});

final locationLocalDataSourceProvider = Provider<LocationLocalDataSource>((ref) {
  final storage = ref.watch(localStorageProvider);
  return SharedPreferencesLocationLocalDataSource(storage);
});

final locationRemoteDataSourceProvider = Provider<LocationRemoteDataSource>((ref) {
  final conn = ref.watch(mockConnectivityServiceProvider);
  return BackendLocationRemoteDataSource(
    isConnectedChecker: () => conn.isConnectedSync,
  );
});

final locationTrackingRepositoryProvider = Provider<LocationTrackingRepository>((ref) {
  final repo = LocationTrackingRepositoryImpl(
    platformDataSource: ref.watch(locationPlatformDataSourceProvider),
    localDataSource: ref.watch(locationLocalDataSourceProvider),
    remoteDataSource: ref.watch(locationRemoteDataSourceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

// ─── State & Notifier ────────────────────────────────────────────────

class LocationTrackingState {
  final TrackingStatus trackingStatus;
  final LocationPermissionState permissionStatus;
  final EmployeeLocation? lastLocation;
  final DateTime? lastUpdateTime;
  final LocationSyncStatus syncStatus;
  final int queuedCount;
  final String? errorMessage;
  final String? activeWorkSessionId;

  const LocationTrackingState({
    this.trackingStatus = TrackingStatus.stopped,
    this.permissionStatus = LocationPermissionState.notDetermined,
    this.lastLocation,
    this.lastUpdateTime,
    this.syncStatus = LocationSyncStatus.idle,
    this.queuedCount = 0,
    this.errorMessage,
    this.activeWorkSessionId,
  });

  bool get isTracking => trackingStatus.isTracking;

  LocationTrackingState copyWith({
    TrackingStatus? trackingStatus,
    LocationPermissionState? permissionStatus,
    EmployeeLocation? lastLocation,
    DateTime? lastUpdateTime,
    LocationSyncStatus? syncStatus,
    int? queuedCount,
    String? errorMessage,
    String? activeWorkSessionId,
    bool clearError = false,
  }) {
    return LocationTrackingState(
      trackingStatus: trackingStatus ?? this.trackingStatus,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastLocation: lastLocation ?? this.lastLocation,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      syncStatus: syncStatus ?? this.syncStatus,
      queuedCount: queuedCount ?? this.queuedCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeWorkSessionId: activeWorkSessionId ?? this.activeWorkSessionId,
    );
  }
}

class LocationTrackingNotifier extends StateNotifier<LocationTrackingState> {
  final LocationTrackingRepository _repository;
  StreamSubscription<EmployeeLocation>? _locationSubscription;

  LocationTrackingNotifier(this._repository) : super(const LocationTrackingState()) {
    _init();
  }

  Future<void> _init() async {
    final perm = await _repository.checkPermissions();
    final queued = await _repository.getQueuedLocations();
    state = state.copyWith(
      permissionStatus: perm,
      queuedCount: queued.length,
    );

    _locationSubscription = _repository.locationStream.listen((location) {
      state = state.copyWith(
        lastLocation: location,
        lastUpdateTime: location.timestamp,
        syncStatus: LocationSyncStatus.synced,
        clearError: true,
      );
    });
  }

  Future<LocationPermissionState> checkPermissions() async {
    final perm = await _repository.checkPermissions();
    state = state.copyWith(permissionStatus: perm);
    return perm;
  }

  Future<LocationPermissionState> requestPermissions({bool requestBackground = true}) async {
    final perm = await _repository.requestPermissions(requestBackground: requestBackground);
    state = state.copyWith(permissionStatus: perm);
    return perm;
  }

  Future<bool> startWorkSessionTracking({
    required String workSessionId,
    required String employeeId,
  }) async {
    state = state.copyWith(
      trackingStatus: TrackingStatus.starting,
      activeWorkSessionId: workSessionId,
      clearError: true,
    );

    final success = await _repository.startTracking(
      workSessionId: workSessionId,
      employeeId: employeeId,
    );

    if (success) {
      state = state.copyWith(
        trackingStatus: _repository.trackingStatus,
        activeWorkSessionId: workSessionId,
      );
    } else {
      state = state.copyWith(
        trackingStatus: TrackingStatus.error,
        errorMessage: 'تعذر بدء تتبع الموقع. يرجى التأكد من منح الأذونات المطلوبة.',
      );
    }

    return success;
  }

  Future<void> stopWorkSessionTracking({String? reason}) async {
    await _repository.stopTracking(reason: reason ?? 'Work session completed');
    final queued = await _repository.getQueuedLocations();
    state = state.copyWith(
      trackingStatus: TrackingStatus.stopped,
      activeWorkSessionId: null,
      queuedCount: queued.length,
    );
  }

  Future<void> syncOfflineQueue() async {
    state = state.copyWith(syncStatus: LocationSyncStatus.syncing);
    final count = await _repository.syncOfflineLocations();
    final remaining = await _repository.getQueuedLocations();
    state = state.copyWith(
      syncStatus: count > 0 ? LocationSyncStatus.synced : LocationSyncStatus.idle,
      queuedCount: remaining.length,
    );
  }

  void handleAppLifecycle(AppLifecycleState lifecycleState) {
    _repository.handleLifecycleChange(lifecycleState);
    state = state.copyWith(trackingStatus: _repository.trackingStatus);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, LocationTrackingState>((ref) {
  final repo = ref.watch(locationTrackingRepositoryProvider);
  return LocationTrackingNotifier(repo);
});
