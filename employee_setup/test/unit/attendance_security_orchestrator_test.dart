import 'package:employee_setup/core/mock/models/app_session.dart';
import 'package:employee_setup/core/mock/seeds/employee_seed.dart';
import 'package:employee_setup/core/storage/shared_prefs_storage.dart';
import 'package:employee_setup/features/attendance/data/api/mock_attendance_api.dart';
import 'package:employee_setup/features/attendance/data/repositories/mock_attendance_repository.dart';
import 'package:employee_setup/features/attendance/data/services/device_integrity_service_impl.dart';
import 'package:employee_setup/features/attendance/data/services/mock_biometric_service.dart';
import 'package:employee_setup/features/attendance/data/services/mock_location_detector_impl.dart';
import 'package:employee_setup/features/attendance/data/services/mock_location_service.dart';
import 'package:employee_setup/features/attendance/data/services/network_risk_service_impl.dart';
import 'package:employee_setup/features/attendance/data/services/screen_overlay_detector_impl.dart';
import 'package:employee_setup/features/attendance/domain/models/attendance.dart';
import 'package:employee_setup/features/attendance/domain/models/attendance_verification_result.dart';
import 'package:employee_setup/features/attendance/domain/models/work_schedule.dart';
import 'package:employee_setup/features/attendance/domain/services/attendance_audit_service.dart';
import 'package:employee_setup/features/attendance/domain/services/attendance_policy_service.dart';
import 'package:employee_setup/features/attendance/domain/services/attendance_security_orchestrator.dart';
import 'package:employee_setup/features/attendance/domain/services/geofence_service.dart';
import 'package:employee_setup/features/attendance/domain/services/work_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:employee_setup/features/auth/domain/models/employee.dart';
import 'package:employee_setup/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class TestMockAuthRepository implements AuthRepository {
  Employee? currentUser;
  TestMockAuthRepository(this.currentUser);

  @override
  Future<Employee?> getCurrentUser() async => currentUser;

  @override
  Future<Employee> signInWithGoogle({String? email}) async => currentUser!;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateEmployee(Employee employee) async {
    currentUser = employee;
  }

  @override
  Stream<Employee?> get authStateChanges => Stream.value(currentUser);
}

void main() {
  group('AttendanceSecurityVerificationOrchestrator Unit Tests', () {
    late SharedPrefsStorage storage;
    late MockAttendanceRepository attendanceRepo;
    late MockAttendanceApi attendanceApi;
    late MockLocationService locationService;
    late MockBiometricService biometricService;
    late MockLocationDetectorImpl mockLocationDetector;
    late ScreenOverlayDetectorImpl screenOverlayDetector;
    late DeviceIntegrityServiceImpl deviceIntegrityService;
    late NetworkRiskServiceImpl networkRiskService;
    late GeofenceService geofenceService;
    late AttendancePolicyService policyService;
    late WorkScheduleService workScheduleService;
    late AttendanceAuditService auditService;
    late TestMockAuthRepository authRepository;
    late AttendanceSecurityVerificationOrchestrator orchestrator;

    late Employee employee;
    late WorkSchedule workSchedule;
    late AppSession session;

    setUp(() async {
      storage = SharedPrefsStorage();
      await storage.init();
      await storage.clear();

      employee = EmployeeSeed.employee.copyWith(
        onboardingCompleted: true,
        allowedRadiusMeters: 10.0,
      );

      session = AppSession.create(
        employeeId: employee.id,
        email: employee.email,
        profileCompleted: true,
        provider: LoginProvider.google,
        deviceId: 'DEV-001',
        deviceType: 'Android',
        deviceModel: 'Pixel 8',
        osVersion: 'Android 14',
        appVersion: '1.0.0',
      );

      workSchedule = WorkSchedule.defaultSchedule(employeeId: employee.id);

      attendanceApi = MockAttendanceApi(getEmployee: () => employee);
      attendanceRepo = MockAttendanceRepository(storage, attendanceApi);
      locationService = MockLocationService();
      biometricService = MockBiometricService();
      mockLocationDetector = MockLocationDetectorImpl();
      screenOverlayDetector = ScreenOverlayDetectorImpl();
      deviceIntegrityService = DeviceIntegrityServiceImpl();
      networkRiskService = NetworkRiskServiceImpl();
      geofenceService = const GeofenceService();
      policyService = const AttendancePolicyService();
      workScheduleService = WorkScheduleService();
      auditService = AttendanceAuditService();
      authRepository = TestMockAuthRepository(employee);

      orchestrator = AttendanceSecurityVerificationOrchestrator(
        locationService: locationService,
        geofenceService: geofenceService,
        mockLocationDetector: mockLocationDetector,
        screenOverlayDetector: screenOverlayDetector,
        biometricService: biometricService,
        deviceIntegrityService: deviceIntegrityService,
        networkRiskService: networkRiskService,
        workScheduleService: workScheduleService,
        policyService: policyService,
        authRepository: authRepository,
        attendanceRepository: attendanceRepo,
        auditService: auditService,
      );
    });

    test('1. Happy path: All 5 security verification stages succeed and record attendance', () async {
      final stepUpdates = <AttendanceSecurityVerificationResult>[];

      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: session,
        isCheckIn: true,
        isOnline: true,
        onStepUpdate: (res) => stepUpdates.add(res),
      );

      expect(result.cloudAuthenticationStatus, equals(CloudAuthenticationStatus.authSessionValid));
      expect(result.screenSecurityStatus, equals(ScreenSecurityStatus.screenSafe));
      expect(result.geofenceStatus, equals(GeofenceVerificationStatus.insideGeofence));
      expect(result.biometricStatus, equals(BiometricVerificationStatus.biometricSuccess));
      expect(result.attendanceRegistrationStatus, equals(CloudAttendanceRegistrationStatus.registered));
      expect(result.isFullyApproved, isTrue);
      expect(result.isFailed, isFalse);
      expect(stepUpdates.length, greaterThanOrEqualTo(5));
    });

    test('2. Expired session fails cloud authentication stage', () async {
      final expiredSession = session.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: expiredSession, // Expired session
        isCheckIn: true,
        isOnline: true,
      );

      expect(result.cloudAuthenticationStatus, equals(CloudAuthenticationStatus.authSessionExpired));
      expect(result.isFailed, isTrue);
      expect(result.geofenceStatus, equals(GeofenceVerificationStatus.idle));
      expect(result.biometricStatus, equals(BiometricVerificationStatus.idle));
    });

    test('3. Unsafe Screen Overlay blocks verification at Stage 2', () async {
      screenOverlayDetector.simulatedOverlayDetected = true;

      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: session,
        isCheckIn: true,
        isOnline: true,
      );

      expect(result.cloudAuthenticationStatus, equals(CloudAuthenticationStatus.authSessionValid));
      expect(result.screenSecurityStatus, equals(ScreenSecurityStatus.screenObscured));
      expect(result.isFailed, isTrue);
      expect(result.geofenceStatus, equals(GeofenceVerificationStatus.idle));
      expect(result.biometricStatus, equals(BiometricVerificationStatus.idle));
    });

    test('4. Location outside workplace geofence radius blocks verification at Stage 3', () async {
      locationService.mode = MockLocationMode.outsideRange;
      locationService.customDistance = 25.0; // outside 10m

      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: session,
        isCheckIn: true,
        isOnline: true,
      );

      expect(result.cloudAuthenticationStatus, equals(CloudAuthenticationStatus.authSessionValid));
      expect(result.screenSecurityStatus, equals(ScreenSecurityStatus.screenSafe));
      expect(result.geofenceStatus, equals(GeofenceVerificationStatus.outsideGeofence));
      expect(result.isFailed, isTrue);
      expect(result.biometricStatus, equals(BiometricVerificationStatus.idle));
    });

    test('5. GPS disabled blocks verification at Stage 3', () async {
      locationService.mode = MockLocationMode.gpsDisabled;

      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: session,
        isCheckIn: true,
        isOnline: true,
      );

      expect(result.geofenceStatus, equals(GeofenceVerificationStatus.locationServiceDisabled));
      expect(result.isFailed, isTrue);
      expect(result.biometricStatus, equals(BiometricVerificationStatus.idle));
    });

    test('6. Location permission denied blocks verification at Stage 3', () async {
      locationService.mode = MockLocationMode.permissionDenied;

      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: session,
        isCheckIn: true,
        isOnline: true,
      );

      expect(result.geofenceStatus, equals(GeofenceVerificationStatus.locationPermissionDenied));
      expect(result.isFailed, isTrue);
    });

    test('7. Mock location signal blocks verification at Stage 3', () async {
      locationService.mode = MockLocationMode.mockLocationDetected;
      mockLocationDetector.simulatedMockDetected = true;

      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: session,
        isCheckIn: true,
        isOnline: true,
      );

      expect(result.geofenceStatus, equals(GeofenceVerificationStatus.mockLocationDetected));
      expect(result.isFailed, isTrue);
    });

    test('8. User cancelling biometric prompt blocks verification at Stage 4', () async {
      biometricService.mode = MockBiometricMode.alwaysCancel;

      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: session,
        isCheckIn: true,
        isOnline: true,
      );

      expect(result.cloudAuthenticationStatus, equals(CloudAuthenticationStatus.authSessionValid));
      expect(result.screenSecurityStatus, equals(ScreenSecurityStatus.screenSafe));
      expect(result.geofenceStatus, equals(GeofenceVerificationStatus.insideGeofence));
      expect(result.biometricStatus, equals(BiometricVerificationStatus.biometricCancelled));
      expect(result.isFailed, isTrue);
      expect(result.attendanceRegistrationStatus, equals(CloudAttendanceRegistrationStatus.idle));
    });

    test('9. Offline attendance successfully queues as PENDING_HR_VERIFICATION', () async {
      final result = await orchestrator.executeVerification(
        employee: employee,
        workSchedule: workSchedule,
        todaySummary: const TodayAttendanceSummary(),
        session: session,
        isCheckIn: true,
        isOnline: false, // Offline mode
      );

      expect(result.isAllLocalChecksSuccessful, isTrue);
      expect(result.attendanceRegistrationStatus, equals(CloudAttendanceRegistrationStatus.offlineQueued));
      expect(result.isPendingHr, isTrue);
    });
  });
}
