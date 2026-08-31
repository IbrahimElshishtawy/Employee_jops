import 'dart:async';
import 'dart:ui' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:employee_setup/core/network/connectivity_service.dart';
import 'package:employee_setup/core/storage/local_storage.dart';
import 'package:employee_setup/core/services/notification_router.dart';
import 'package:employee_setup/core/mock/models/app_session.dart';
import 'package:employee_setup/features/location_tracking/domain/entities/employee_location.dart';
import 'package:employee_setup/features/location_tracking/domain/entities/tracking_enums.dart';
import 'package:employee_setup/features/location_tracking/data/models/employee_location_model.dart';
import 'package:employee_setup/features/location_tracking/data/datasources/location_local_data_source.dart';
import 'package:employee_setup/features/location_tracking/data/datasources/location_platform_data_source.dart';
import 'package:employee_setup/features/location_tracking/data/datasources/location_remote_data_source.dart';
import 'package:employee_setup/features/location_tracking/data/repositories/location_tracking_repository_impl.dart';

// In-Memory Storage for Testing
class InMemoryStorage implements LocalStorage {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> init() async {}

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }
}

// Mock Platform Data Source
class MockLocationPlatformDataSource implements LocationPlatformDataSource {
  LocationPermissionState permissionState = LocationPermissionState.foregroundGranted;
  bool isServiceEnabled = true;
  final StreamController<EmployeeLocation> _streamController =
      StreamController<EmployeeLocation>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => isServiceEnabled;

  @override
  Future<LocationPermissionState> checkPermission() async => permissionState;

  @override
  Future<LocationPermissionState> requestPermission({bool requestBackground = true}) async {
    return permissionState;
  }

  @override
  Future<EmployeeLocation?> getCurrentPosition() async {
    if (!isServiceEnabled || permissionState.isDenied) return null;
    return EmployeeLocation(
      latitude: 30.0444,
      longitude: 31.2357,
      accuracy: 5.0,
      timestamp: DateTime.now(),
      source: LocationSource.gps,
    );
  }

  @override
  Stream<EmployeeLocation> getPositionStream({
    int intervalSeconds = 30,
    int distanceFilterMeters = 10,
  }) {
    return _streamController.stream;
  }

  void emitLocation(EmployeeLocation location) {
    _streamController.add(location);
  }

  void dispose() {
    _streamController.close();
  }
}

// Mock Connectivity Service
class TestConnectivityService implements ConnectivityService {
  bool _connected = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  void setConnected(bool value) {
    _connected = value;
    _controller.add(value);
  }

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('1. EmployeeLocation Domain & Model Tests', () {
    test('EmployeeLocation serialization and deserialization matches', () {
      final now = DateTime(2026, 8, 31, 12, 0, 0);
      final location = EmployeeLocation(
        latitude: 30.05,
        longitude: 31.25,
        accuracy: 3.5,
        timestamp: now,
        source: LocationSource.background,
        workSessionId: 'SESSION-123',
        employeeId: 'EMP-001',
      );

      final model = EmployeeLocationModel.fromEntity(location);
      final json = model.toJson();
      final fromJson = EmployeeLocationModel.fromJson(json);

      expect(fromJson.latitude, 30.05);
      expect(fromJson.longitude, 31.25);
      expect(fromJson.accuracy, 3.5);
      expect(fromJson.workSessionId, 'SESSION-123');
      expect(fromJson.employeeId, 'EMP-001');
      expect(fromJson.source, LocationSource.background);
    });
  });

  group('2. Offline Location Queue (Bounded Capacity & Persistence)', () {
    late InMemoryStorage storage;
    late SharedPreferencesLocationLocalDataSource localDataSource;

    setUp(() {
      storage = InMemoryStorage();
      localDataSource = SharedPreferencesLocationLocalDataSource(storage);
    });

    test('Enqueues and retrieves offline locations correctly', () async {
      final loc1 = EmployeeLocation(
        latitude: 30.01,
        longitude: 31.01,
        accuracy: 4.0,
        timestamp: DateTime.now(),
        workSessionId: 'S-1',
      );
      final loc2 = EmployeeLocation(
        latitude: 30.02,
        longitude: 31.02,
        accuracy: 4.5,
        timestamp: DateTime.now().add(const Duration(seconds: 30)),
        workSessionId: 'S-1',
      );

      await localDataSource.enqueueLocation(loc1);
      await localDataSource.enqueueLocation(loc2);

      final queued = await localDataSource.getQueuedLocations();
      expect(queued.length, 2);
      expect(queued[0].latitude, 30.01);
      expect(queued[1].latitude, 30.02);
    });

    test('Removes synced locations from queue without data loss of other entries', () async {
      final loc1 = EmployeeLocation(
        latitude: 30.01,
        longitude: 31.01,
        accuracy: 4.0,
        timestamp: DateTime(2026, 8, 31, 10, 0, 0),
      );
      final loc2 = EmployeeLocation(
        latitude: 30.02,
        longitude: 31.02,
        accuracy: 4.0,
        timestamp: DateTime(2026, 8, 31, 10, 1, 0),
      );

      await localDataSource.enqueueLocation(loc1);
      await localDataSource.enqueueLocation(loc2);

      // Remove loc1
      await localDataSource.removeLocations([loc1]);

      final remaining = await localDataSource.getQueuedLocations();
      expect(remaining.length, 1);
      expect(remaining[0].latitude, 30.02);
    });
  });

  group('3. Location Tracking Repository Lifecycle & Work Session Policy', () {
    late MockLocationPlatformDataSource platformDs;
    late InMemoryStorage storage;
    late SharedPreferencesLocationLocalDataSource localDs;
    late BackendLocationRemoteDataSource remoteDs;
    late TestConnectivityService connectivity;
    late LocationTrackingRepositoryImpl repo;

    setUp(() {
      platformDs = MockLocationPlatformDataSource();
      storage = InMemoryStorage();
      localDs = SharedPreferencesLocationLocalDataSource(storage);
      remoteDs = BackendLocationRemoteDataSource();
      connectivity = TestConnectivityService();

      repo = LocationTrackingRepositoryImpl(
        platformDataSource: platformDs,
        localDataSource: localDs,
        remoteDataSource: remoteDs,
        connectivityService: connectivity,
      );
    });

    tearDown(() async {
      await repo.dispose();
      platformDs.dispose();
      connectivity.dispose();
    });

    test('Starts tracking when work session starts with valid permissions', () async {
      final started = await repo.startTracking(
        workSessionId: 'WORK-SESSION-999',
        employeeId: 'EMP-CAIRO-01',
      );

      expect(started, isTrue);
      expect(repo.trackingStatus.isTracking, isTrue);
      expect(repo.activeWorkSessionId, 'WORK-SESSION-999');
    });

    test('Refuses to start tracking when permission is denied', () async {
      platformDs.permissionState = LocationPermissionState.denied;

      final started = await repo.startTracking(
        workSessionId: 'WORK-SESSION-999',
        employeeId: 'EMP-CAIRO-01',
      );

      expect(started, isFalse);
      expect(repo.trackingStatus, TrackingStatus.error);
    });

    test('Stops tracking when work session ends or user logs out', () async {
      await repo.startTracking(
        workSessionId: 'WORK-SESSION-999',
        employeeId: 'EMP-CAIRO-01',
      );
      expect(repo.trackingStatus.isTracking, isTrue);

      await repo.stopTracking(reason: 'Check-Out completed');
      expect(repo.trackingStatus, TrackingStatus.stopped);
      expect(repo.activeWorkSessionId, isNull);
    });

    test('Distinguishes foreground and background lifecycle transitions', () async {
      await repo.startTracking(
        workSessionId: 'WORK-SESSION-999',
        employeeId: 'EMP-CAIRO-01',
      );
      expect(repo.trackingStatus, TrackingStatus.activeForeground);

      // App backgrounded
      repo.handleLifecycleChange(AppLifecycleState.paused);
      expect(repo.trackingStatus, TrackingStatus.activeBackground);

      // App foregrounded
      repo.handleLifecycleChange(AppLifecycleState.resumed);
      expect(repo.trackingStatus, TrackingStatus.activeForeground);
    });
  });

  group('4. Notification Routing & Deep Link Payload Handling', () {
    test('Resolves HR_MESSAGE to chat route', () {
      final payload = const NotificationPayload(
        type: NotificationType.hrMessage,
        conversationId: 'CONV-HR-001',
      );

      expect(payload.getResolvedRoute(), '/communication/chat/CONV-HR-001');
    });

    test('Resolves ATTENDANCE_REMINDER to attendance route', () {
      final payload = const NotificationPayload(
        type: NotificationType.attendanceReminder,
      );

      expect(payload.getResolvedRoute(), '/attendance');
    });

    test('Resolves DEPARTMENT_REQUEST to request details or requests hub', () {
      final payload = const NotificationPayload(
        type: NotificationType.departmentRequest,
        requestId: 'REQ-12345',
      );

      expect(payload.getResolvedRoute(), '/communication/request/REQ-12345');
    });

    test('Safely parses JSON payload string', () {
      const jsonStr = '{"type":"HR_ANNOUNCEMENT","targetId":"NOTIF-99"}';
      final parsed = NotificationPayload.fromRawPayload(jsonStr);

      expect(parsed.type, NotificationType.hrAnnouncement);
      expect(parsed.targetId, 'NOTIF-99');
      expect(parsed.getResolvedRoute(), '/notifications/NOTIF-99');
    });
  });

  group('5. Device Session Tracking Metadata', () {
    test('AppSession holds notification state, token, and work session status', () {
      final session = AppSession.create(
        employeeId: 'EMP-01',
        email: 'employee@cyberwise.com',
        deviceId: 'DEV-PIXEL-8',
        notificationPermissionState: 'granted',
        notificationToken: 'FCM-TOKEN-XYZ',
        workSessionStatus: 'active',
        workSessionId: 'WS-001',
        trackingActive: true,
      );

      expect(session.notificationPermissionState, 'granted');
      expect(session.notificationToken, 'FCM-TOKEN-XYZ');
      expect(session.workSessionStatus, 'active');
      expect(session.trackingActive, isTrue);

      final json = session.toJson();
      final restored = AppSession.fromJson(json);

      expect(restored.notificationPermissionState, 'granted');
      expect(restored.notificationToken, 'FCM-TOKEN-XYZ');
      expect(restored.workSessionStatus, 'active');
      expect(restored.trackingActive, isTrue);
    });
  });
}
