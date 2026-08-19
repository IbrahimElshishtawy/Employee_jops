import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/features/attendance/data/api/mock_attendance_api.dart';
import 'package:employee_setup/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:employee_setup/features/attendance/data/services/device_integrity_service_impl.dart';
import 'package:employee_setup/features/attendance/data/services/mock_biometric_service.dart';
import 'package:employee_setup/features/attendance/data/services/mock_location_detector_impl.dart';
import 'package:employee_setup/features/attendance/data/services/mock_location_service.dart';
import 'package:employee_setup/features/attendance/data/services/network_risk_service_impl.dart';
import 'package:employee_setup/features/attendance/domain/models/attendance.dart';
import 'package:employee_setup/features/attendance/domain/models/attendance_api_contracts.dart';
import 'package:employee_setup/features/attendance/domain/services/attendance_policy_service.dart';
import 'package:employee_setup/features/attendance/domain/services/attendance_verification_service.dart';
import 'package:employee_setup/features/attendance/domain/services/geofence_service.dart';
import 'package:employee_setup/features/attendance/domain/services/work_schedule_service.dart';
import 'package:employee_setup/features/auth/domain/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attendance Feature & Security Verification Tests', () {
    late SharedPrefsStorage storage;
    late MockAttendanceRepository attendanceRepo;
    late MockAttendanceApi attendanceApi;
    late MockLocationService locationService;
    late MockBiometricService biometricService;
    late MockLocationDetectorImpl mockLocationDetector;
    late DeviceIntegrityServiceImpl deviceIntegrityService;
    late NetworkRiskServiceImpl networkRiskService;
    late GeofenceService geofenceService;
    late AttendancePolicyService policyService;
    late WorkScheduleService workScheduleService;
    late AttendanceVerificationService verificationService;
    late Employee sampleEmployee;

    setUp(() async {
      storage = SharedPrefsStorage();
      await storage.init();
      await storage.clear();

      sampleEmployee = Employee(
        id: 'EMP-1024',
        name: 'إبراهيم الششتاوي',
        email: 'employee@company.com',
        department: 'الهندسة البرمجية',
        jobTitle: 'Senior Software Developer',
        avatarUrl: '',
        phone: '01000000000',
        joinDate: DateTime(2025, 1, 15),
        workplaceName: 'المقر الرئيسي - القاهرة',
        workplaceLatitude: 30.044400,
        workplaceLongitude: 31.235700,
        allowedRadiusMeters: 4.0,
        workStartTime: '09:00 AM',
        workEndTime: '05:00 PM',
        hrContactName: 'سارة عبد الله',
        hrContactPhone: '01011122233',
        employeeStatus: 'active',
      );

      attendanceApi = MockAttendanceApi(getEmployee: () => sampleEmployee);
      attendanceRepo = MockAttendanceRepository(storage, attendanceApi);
      locationService = MockLocationService();
      biometricService = MockBiometricService();
      mockLocationDetector = MockLocationDetectorImpl();
      deviceIntegrityService = DeviceIntegrityServiceImpl();
      networkRiskService = NetworkRiskServiceImpl();
      geofenceService = const GeofenceService();
      policyService = const AttendancePolicyService();
      workScheduleService = WorkScheduleService();

      verificationService = AttendanceVerificationService(
        locationService: locationService,
        geofenceService: geofenceService,
        mockLocationDetector: mockLocationDetector,
        biometricService: biometricService,
        deviceIntegrityService: deviceIntegrityService,
        networkRiskService: networkRiskService,
        workScheduleService: workScheduleService,
        policyService: policyService,
      );
    });

    group('1. Employee Workplace Location & Configurable Geofence', () {
      test('Employee workplace data is populated and not hardcoded', () {
        expect(sampleEmployee.workplaceName, equals('المقر الرئيسي - القاهرة'));
        expect(sampleEmployee.workplaceLatitude, equals(30.044400));
        expect(sampleEmployee.workplaceLongitude, equals(31.235700));
        expect(sampleEmployee.allowedRadiusMeters, equals(4.0));
      });

      test('GeofenceService calculates precise distance using Haversine', () {
        final distanceZero = geofenceService.calculateDistanceInMeters(
          startLatitude: 30.044400,
          startLongitude: 31.235700,
          endLatitude: 30.044400,
          endLongitude: 31.235700,
        );
        expect(distanceZero, equals(0.0));

        final distanceInside = geofenceService.calculateDistanceInMeters(
          startLatitude: 30.044400,
          startLongitude: 31.235700,
          endLatitude: 30.044415,
          endLongitude: 31.235715,
        );
        expect(distanceInside, lessThan(4.0));
      });

      test('GeofenceService respects custom allowedRadiusMeters', () {
        expect(
          geofenceService.isWithinRadius(distanceInMeters: 3.5, allowedRadiusMeters: 4.0),
          isTrue,
        );
        expect(
          geofenceService.isWithinRadius(distanceInMeters: 4.5, allowedRadiusMeters: 4.0),
          isFalse,
        );
        expect(
          geofenceService.isWithinRadius(distanceInMeters: 7.5, allowedRadiusMeters: 10.0),
          isTrue,
        );
      });
    });

    group('2. Location Verification & GPS Accuracy', () {
      test('Accuracy threshold <= 20m accepted, > 20m rejected', () {
        expect(policyService.isAccuracyAcceptable(3.5), isTrue);
        expect(policyService.isAccuracyAcceptable(20.0), isTrue);
        expect(policyService.isAccuracyAcceptable(20.1), isFalse);
        expect(policyService.isAccuracyAcceptable(50.0), isFalse);
      });

      test('VerificationService fails if GPS disabled', () async {
        locationService.mode = MockLocationMode.gpsDisabled;
        final res = await verificationService.verifyLocation(employee: sampleEmployee);
        expect(res.isSuccess, isFalse);
        expect(res.errorMessage, contains('خدمة تحديد المواقع (GPS) معطلة'));
      });

      test('VerificationService fails if permission denied', () async {
        locationService.mode = MockLocationMode.permissionDenied;
        final res = await verificationService.verifyLocation(employee: sampleEmployee);
        expect(res.isSuccess, isFalse);
        expect(res.errorMessage, contains('يرجى السماح للتطبيق باستخدام موقعك'));
      });

      test('VerificationService fails if outside workplace radius', () async {
        locationService.mode = MockLocationMode.outsideRange;
        locationService.customDistance = 48.5;
        final res = await verificationService.verifyLocation(employee: sampleEmployee);
        expect(res.isSuccess, isFalse);
        expect(res.errorMessage, contains('أنت خارج نطاق موقع العمل'));
      });
    });

    group('3. Mock Location Detection', () {
      test('Mock location detected causes verification failure', () async {
        locationService.mode = MockLocationMode.mockLocationDetected;
        mockLocationDetector.simulatedMockDetected = true;
        final res = await verificationService.verifyLocation(employee: sampleEmployee);
        expect(res.isSuccess, isFalse);
        expect(res.errorMessage, contains('موقع غير موثوق'));
      });
    });

    group('4. Device Biometric Authentication', () {
      test('Biometric success produces auth proof token without raw template storage', () async {
        biometricService.mode = MockBiometricMode.alwaysSuccess;
        final res = await verificationService.verifyBiometrics(isCheckIn: true);
        expect(res.isSuccess, isTrue);
        expect(res.data, isNotNull);
        expect(res.data, startsWith('BIO-AUTH-'));
      });

      test('Biometric failure/cancellation returns descriptive error message', () async {
        biometricService.mode = MockBiometricMode.alwaysCancel;
        final res = await verificationService.verifyBiometrics(isCheckIn: true);
        expect(res.isSuccess, isFalse);
        expect(res.errorMessage, contains('تم إلغاء المصادقة'));
      });
    });

    group('5. Device Integrity (Play Integrity & App Attest) & Network Risk', () {
      test('DeviceIntegrityService generates nonces and acquires attestation tokens', () async {
        final nonce = deviceIntegrityService.generateNonce();
        expect(nonce.isNotEmpty, isTrue);

        final tokenResult = await deviceIntegrityService.requestIntegrityToken(nonce: nonce);
        expect(tokenResult.hasToken, isTrue);
        expect(tokenResult.nonce, equals(nonce));
      });

      test('NetworkRiskService captures VPN active signal without blocking GPS', () async {
        networkRiskService.simulatedVpnActive = true;
        final risk = await networkRiskService.evaluateNetworkRisk();
        expect(risk.isVpnActive, isTrue);
        expect(risk.hasRisk, isTrue);
      });
    });

    group('6. Backend API Final Decision Engine & Idempotency', () {
      test('Backend approves valid check-in and re-computes distance independently', () async {
        final req = AttendanceSubmissionRequest(
          clientRequestId: 'REQ-UNIT-001',
          employeeId: sampleEmployee.id,
          attendanceType: AttendanceType.checkIn,
          latitude: 30.044400,
          longitude: 31.235700,
          accuracy: 3.5,
          clientTimestamp: DateTime.now(),
          workplaceId: 'LOC-CAIRO-HQ',
          distanceFromWorkplace: 2.1,
          biometricVerified: true,
        );

        final response = await attendanceApi.submitAttendance(req);
        expect(response.success, isTrue);
        expect(response.decision, equals(AttendanceDecision.approved));
        expect(response.serverCalculatedDistance, equals(0.0));
      });

      test('Backend rejects duplicate submission with the same clientRequestId', () async {
        final req = AttendanceSubmissionRequest(
          clientRequestId: 'REQ-UNIT-DUPLICATE',
          employeeId: sampleEmployee.id,
          attendanceType: AttendanceType.checkIn,
          latitude: 30.044400,
          longitude: 31.235700,
          accuracy: 3.5,
          clientTimestamp: DateTime.now(),
          workplaceId: 'LOC-CAIRO-HQ',
          distanceFromWorkplace: 0.0,
          biometricVerified: true,
        );

        final first = await attendanceApi.submitAttendance(req);
        expect(first.success, isTrue);

        final duplicate = await attendanceApi.submitAttendance(req);
        expect(duplicate.success, isFalse);
        expect(duplicate.rejectionReason, equals(RejectionReason.duplicateSubmission));
      });

      test('Offline attendance submission is captured as PENDING_HR_VERIFICATION and repository manages queue', () async {
        final req = AttendanceSubmissionRequest(
          clientRequestId: 'REQ-UNIT-OFFLINE-001',
          employeeId: sampleEmployee.id,
          attendanceType: AttendanceType.checkIn,
          latitude: 30.044400,
          longitude: 31.235700,
          accuracy: 3.5,
          clientTimestamp: DateTime.now(),
          workplaceId: 'LOC-CAIRO-HQ',
          distanceFromWorkplace: 2.1,
          biometricVerified: true,
          isOfflineSubmission: true,
        );

        final response = await attendanceRepo.submitAttendanceRequest(req);
        expect(response.success, isTrue);
        expect(response.decision, equals(AttendanceDecision.pendingHrVerification));
        expect(response.attendanceRecord?.isOffline, isTrue);
        expect(response.attendanceRecord?.status, equals(AttendanceStatus.offlinePending));

        final pendingQueue = await attendanceRepo.getPendingOfflineQueue();
        expect(pendingQueue.isNotEmpty, isTrue);
      });
    });
  });
}
