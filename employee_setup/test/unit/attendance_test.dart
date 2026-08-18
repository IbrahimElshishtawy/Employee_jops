import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:employee_setup/features/attendance/data/services/mock_biometric_service.dart';
import 'package:employee_setup/features/attendance/data/services/mock_location_service.dart';
import 'package:employee_setup/features/attendance/domain/models/attendance.dart';
import 'package:employee_setup/features/attendance/domain/models/location_result.dart';
import 'package:employee_setup/features/attendance/domain/services/attendance_location_policy.dart';
import 'package:employee_setup/features/attendance/domain/services/biometric_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attendance Feature Tests', () {
    late SharedPrefsStorage storage;
    late MockAttendanceRepository attendanceRepo;
    late MockLocationService locationService;
    late MockBiometricService biometricService;

    setUp(() async {
      storage = SharedPrefsStorage();
      await storage.init();
      await storage.clear();
      attendanceRepo = MockAttendanceRepository(storage);
      locationService = MockLocationService();
      biometricService = MockBiometricService();
    });

    group('4-Meter Geofence & Location Policy Tests', () {
      test('Distance <= 4.0 meters is inside allowed zone', () {
        expect(AttendanceLocationPolicy.isWithinAllowedRadius(0.0), isTrue);
        expect(AttendanceLocationPolicy.isWithinAllowedRadius(2.3), isTrue);
        expect(AttendanceLocationPolicy.isWithinAllowedRadius(4.0), isTrue);
      });

      test('Distance > 4.0 meters is outside allowed zone', () {
        expect(AttendanceLocationPolicy.isWithinAllowedRadius(4.01), isFalse);
        expect(AttendanceLocationPolicy.isWithinAllowedRadius(8.5), isFalse);
        expect(AttendanceLocationPolicy.isWithinAllowedRadius(48.5), isFalse);
      });

      test('Negative distance is rejected', () {
        expect(AttendanceLocationPolicy.isWithinAllowedRadius(-1.0), isFalse);
      });

      test('LocationService inside range reports distance <= 4m', () async {
        locationService.mode = MockLocationMode.insideRange;
        locationService.customDistance = 2.3;
        final loc = await locationService.getCurrentLocation();
        expect(loc.status, equals(LocationStatus.insideRange));
        expect(loc.distanceFromOfficeMeters, lessThanOrEqualTo(4.0));
        expect(loc.isInsideRange, isTrue);
      });

      test('LocationService outside range reports isInsideRange = false', () async {
        locationService.mode = MockLocationMode.outsideRange;
        locationService.customDistance = 48.5;
        final loc = await locationService.getCurrentLocation();
        expect(loc.status, equals(LocationStatus.outsideRange));
        expect(loc.isInsideRange, isFalse);
      });

      test('Location permission denied reports isPermissionDenied = true', () async {
        locationService.mode = MockLocationMode.permissionDenied;
        final loc = await locationService.getCurrentLocation();
        expect(loc.isPermissionDenied, isTrue);
        expect(loc.isInsideRange, isFalse);
      });
    });

    group('Biometric Authentication Tests', () {
      test('BiometricService success verification', () async {
        biometricService.mode = MockBiometricMode.alwaysSuccess;
        final res = await biometricService.authenticate();
        expect(res, equals(BiometricAuthResult.success));
      });

      test('BiometricService failed verification', () async {
        biometricService.mode = MockBiometricMode.alwaysFail;
        final res = await biometricService.authenticate();
        expect(res, equals(BiometricAuthResult.failed));
      });

      test('BiometricService cancelled verification', () async {
        biometricService.mode = MockBiometricMode.alwaysCancel;
        final res = await biometricService.authenticate();
        expect(res, equals(BiometricAuthResult.cancelled));
      });

      test('BiometricService unavailable device verification', () async {
        biometricService.mode = MockBiometricMode.notAvailable;
        final res = await biometricService.authenticate();
        expect(res, equals(BiometricAuthResult.notAvailable));
        expect(await biometricService.canCheckBiometrics(), isFalse);
      });
    });

    group('Check-In / Check-Out Lifecycle Tests', () {
      test('CheckIn online updates today status and adds to history', () async {
        final checkIn = await attendanceRepo.checkIn(
          employeeId: 'EMP-1024',
          latitude: 30.0444,
          longitude: 31.2357,
          distance: 2.1,
          biometricVerified: true,
          isOffline: false,
        );

        expect(checkIn.type, equals(AttendanceType.checkIn));
        expect(checkIn.status, equals(AttendanceStatus.success));

        final today = await attendanceRepo.getTodayStatus('EMP-1024');
        expect(today.hasCheckedIn, isTrue);
        expect(today.hasCheckedOut, isFalse);

        final history = await attendanceRepo.getHistory('EMP-1024');
        expect(history.first.id, equals(checkIn.id));
      });

      test('CheckIn offline queues pending item with Pending HR status', () async {
        final checkIn = await attendanceRepo.checkIn(
          employeeId: 'EMP-1024',
          latitude: 30.0444,
          longitude: 31.2357,
          distance: 2.1,
          biometricVerified: true,
          isOffline: true,
        );

        expect(checkIn.isOffline, isTrue);
        expect(checkIn.status, equals(AttendanceStatus.offlinePending));

        final pending = await attendanceRepo.getPendingOfflineQueue();
        expect(pending.length, equals(1));
        expect(pending.first.id, equals(checkIn.id));

        final syncedCount = await attendanceRepo.syncPendingAttendance();
        expect(syncedCount, equals(1));
        expect((await attendanceRepo.getPendingOfflineQueue()).isEmpty, isTrue);
      });

      test('CheckOut completes today attendance flow', () async {
        await attendanceRepo.checkIn(
          employeeId: 'EMP-1024',
          latitude: 30.0444,
          longitude: 31.2357,
          distance: 2.1,
          biometricVerified: true,
          isOffline: false,
        );

        final checkOut = await attendanceRepo.checkOut(
          employeeId: 'EMP-1024',
          latitude: 30.0444,
          longitude: 31.2357,
          distance: 2.2,
          biometricVerified: true,
          isOffline: false,
        );

        expect(checkOut.type, equals(AttendanceType.checkOut));

        final today = await attendanceRepo.getTodayStatus('EMP-1024');
        expect(today.hasCheckedIn, isTrue);
        expect(today.hasCheckedOut, isTrue);
      });
    });
  });
}
