import 'package:employee_setup/core/utils/validators.dart';
import 'package:employee_setup/features/attendance/data/api/mock_attendance_api.dart';
import 'package:employee_setup/features/attendance/domain/models/attendance.dart';
import 'package:employee_setup/features/attendance/domain/models/attendance_api_contracts.dart';
import 'package:employee_setup/features/attendance/domain/models/device_integrity_result.dart';
import 'package:employee_setup/features/attendance/domain/models/network_risk_info.dart';
import 'package:employee_setup/features/auth/domain/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security & Validation Audit Tests', () {
    late Employee testEmployee;
    late MockAttendanceApi api;

    setUp(() {
      testEmployee = Employee(
        id: 'EMP-SEC-001',
        name: 'Secured Test Employee',
        email: 'secured.employee@cyberwise.ie',
        role: 'employee',
        department: 'Cybersecurity',
        jobTitle: 'Security Analyst',
        region: 'Cairo',
        managerId: 'MGR-001',
        managerName: 'Security Lead',
        isActive: true,
        employeeStatus: 'active',
        onboardingCompleted: true,
        workplaceLatitude: 30.044400,
        workplaceLongitude: 31.235700,
        allowedRadiusMeters: 4.0,
      );

      api = MockAttendanceApi(getEmployee: () => testEmployee);
    });

    test('1. Valid attendance request with correct GPS and biometrics is approved', () async {
      final request = AttendanceSubmissionRequest(
        clientRequestId: 'REQ-SEC-001',
        employeeId: testEmployee.id,
        attendanceType: AttendanceType.checkIn,
        latitude: 30.044400,
        longitude: 31.235700,
        accuracy: 3.5,
        clientTimestamp: DateTime.now(),
        workplaceId: 'LOC-CAIRO-HQ',
        distanceFromWorkplace: 0.0,
        biometricVerified: true,
      );

      final response = await api.submitAttendance(request);
      expect(response.success, isTrue);
      expect(response.decision, equals(AttendanceDecision.approved));
      expect(response.serverCalculatedDistance, isNotNull);
      expect(response.serverCalculatedDistance! <= 4.0, isTrue);
    });

    test('2. Replay attack rejection: Duplicate clientRequestId is rejected', () async {
      final request = AttendanceSubmissionRequest(
        clientRequestId: 'REQ-REPLAY-DUP-01',
        employeeId: testEmployee.id,
        attendanceType: AttendanceType.checkIn,
        latitude: 30.044400,
        longitude: 31.235700,
        accuracy: 3.5,
        clientTimestamp: DateTime.now(),
        workplaceId: 'LOC-CAIRO-HQ',
        distanceFromWorkplace: 0.0,
        biometricVerified: true,
      );

      // First submission succeeds
      final response1 = await api.submitAttendance(request);
      expect(response1.success, isTrue);

      // Second identical submission must be rejected
      final response2 = await api.submitAttendance(request);
      expect(response2.success, isFalse);
      expect(response2.rejectionReason, equals(RejectionReason.duplicateSubmission));
    });

    test('3. Outside workplace geofence is rejected on server calculation', () async {
      final request = AttendanceSubmissionRequest(
        clientRequestId: 'REQ-OUTSIDE-01',
        employeeId: testEmployee.id,
        attendanceType: AttendanceType.checkIn,
        latitude: 30.050000, // far from office
        longitude: 31.240000,
        accuracy: 3.5,
        clientTimestamp: DateTime.now(),
        workplaceId: 'LOC-CAIRO-HQ',
        distanceFromWorkplace: 0.0, // Client tries to spoof 0 distance
        biometricVerified: true,
      );

      final response = await api.submitAttendance(request);
      expect(response.success, isFalse);
      expect(response.decision, equals(AttendanceDecision.rejected));
      expect(response.rejectionReason, equals(RejectionReason.outsideGeofence));
    });

    test('4. Inactive employee cannot record attendance', () async {
      testEmployee = testEmployee.copyWith(isActive: false, employeeStatus: 'suspended');

      final request = AttendanceSubmissionRequest(
        clientRequestId: 'REQ-INACTIVE-01',
        employeeId: testEmployee.id,
        attendanceType: AttendanceType.checkIn,
        latitude: 30.044400,
        longitude: 31.235700,
        accuracy: 3.5,
        clientTimestamp: DateTime.now(),
        workplaceId: 'LOC-CAIRO-HQ',
        distanceFromWorkplace: 0.0,
        biometricVerified: true,
      );

      final response = await api.submitAttendance(request);
      expect(response.success, isFalse);
      expect(response.rejectionReason, equals(RejectionReason.employeeInactive));
    });

    test('5. Unacceptable GPS accuracy (> 20m) is rejected by backend', () async {
      final request = AttendanceSubmissionRequest(
        clientRequestId: 'REQ-LOW-ACCURACY-01',
        employeeId: testEmployee.id,
        attendanceType: AttendanceType.checkIn,
        latitude: 30.044400,
        longitude: 31.235700,
        accuracy: 45.0, // Poor accuracy > 20m
        clientTimestamp: DateTime.now(),
        workplaceId: 'LOC-CAIRO-HQ',
        distanceFromWorkplace: 0.0,
        biometricVerified: true,
      );

      final response = await api.submitAttendance(request);
      expect(response.success, isFalse);
      expect(response.rejectionReason, equals(RejectionReason.unacceptableGpsAccuracy));
    });

    test('6. Unverified biometric submission is rejected', () async {
      final request = AttendanceSubmissionRequest(
        clientRequestId: 'REQ-NO-BIO-01',
        employeeId: testEmployee.id,
        attendanceType: AttendanceType.checkIn,
        latitude: 30.044400,
        longitude: 31.235700,
        accuracy: 3.0,
        clientTimestamp: DateTime.now(),
        workplaceId: 'LOC-CAIRO-HQ',
        distanceFromWorkplace: 0.0,
        biometricVerified: false, // Biometric failed / bypassed
      );

      final response = await api.submitAttendance(request);
      expect(response.success, isFalse);
      expect(response.rejectionReason, equals(RejectionReason.biometricVerificationMissing));
    });

    test('7. Timestamp drift exceeding 5 minutes is rejected', () async {
      final request = AttendanceSubmissionRequest(
        clientRequestId: 'REQ-STALE-TIME-01',
        employeeId: testEmployee.id,
        attendanceType: AttendanceType.checkIn,
        latitude: 30.044400,
        longitude: 31.235700,
        accuracy: 3.0,
        clientTimestamp: DateTime.now().subtract(const Duration(minutes: 15)), // 15 mins old
        workplaceId: 'LOC-CAIRO-HQ',
        distanceFromWorkplace: 0.0,
        biometricVerified: true,
      );

      final response = await api.submitAttendance(request);
      expect(response.success, isFalse);
      expect(response.rejectionReason, equals(RejectionReason.timestampDriftExceeded));
    });

    test('8. Offline attendance is marked as pending HR verification', () async {
      final request = AttendanceSubmissionRequest(
        clientRequestId: 'REQ-OFFLINE-01',
        employeeId: testEmployee.id,
        attendanceType: AttendanceType.checkIn,
        latitude: 30.044400,
        longitude: 31.235700,
        accuracy: 3.0,
        clientTimestamp: DateTime.now(),
        workplaceId: 'LOC-CAIRO-HQ',
        distanceFromWorkplace: 0.0,
        biometricVerified: true,
        isOfflineSubmission: true,
      );

      final response = await api.submitAttendance(request);
      expect(response.success, isTrue);
      expect(response.decision, equals(AttendanceDecision.pendingHrVerification));
      expect(response.rejectionReason, equals(RejectionReason.offlineSubmissionLogged));
      expect(response.attendanceRecord?.isOffline, isTrue);
    });

    test('9. Input Validators correctly enforce security constraints', () {
      // Email
      expect(Validators.email('test@company.com'), isNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email(''), isNotNull);

      // Phone
      expect(Validators.phone('01012345678'), isNull);
      expect(Validators.phone('+201123456789'), isNull);
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone('abc-not-phone'), isNotNull);

      // National ID
      expect(Validators.nationalId('29801011234567'), isNull);
      expect(Validators.nationalId('30101011234567'), isNull);
      expect(Validators.nationalId('123456'), isNotNull); // Too short
      expect(Validators.nationalId('49801011234567'), isNotNull); // Invalid century start

      // Length bounds
      expect(Validators.maxLength('short', 10), isNull);
      expect(Validators.maxLength('this text is way too long for max length', 10), isNotNull);
      expect(Validators.minLength('hello', 3), isNull);
      expect(Validators.minLength('hi', 5), isNotNull);
    });
  });
}
