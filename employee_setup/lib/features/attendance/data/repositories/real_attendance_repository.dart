import 'package:uuid/uuid.dart';

import '../../../../core/mock/mock_database.dart';
import '../../domain/models/attendance.dart';
import '../../domain/models/attendance_api_contracts.dart';
import '../../domain/models/attendance_state_type.dart';
import '../../domain/models/device_integrity_result.dart';
import '../../domain/models/network_risk_info.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class RealAttendanceRepository implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final MockDatabaseNotifier db;
  final Uuid _uuid = const Uuid();

  RealAttendanceRepository({
    required this.remoteDataSource,
    required this.db,
  });

  @override
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId) async {
    // 1. Try remote API
    final remoteToday = await remoteDataSource.getTodayAttendance();
    if (remoteToday != null) {
      db.updateAttendanceRecord(remoteToday);
    }
    // 2. Return current database summary
    return db.todayAttendanceSummary;
  }

  @override
  Future<AttendanceVerificationResponse> submitAttendanceRequest(
    AttendanceSubmissionRequest request,
  ) async {
    if (request.attendanceType == AttendanceType.checkIn) {
      final response = await remoteDataSource.checkIn(request);
      if (response.success && response.attendanceRecord != null) {
        db.updateAttendanceRecord(response.attendanceRecord!);
      }
      return response;
    } else {
      final response = await remoteDataSource.checkOut(request);
      if (response.success && response.attendanceRecord != null) {
        db.updateAttendanceRecord(response.attendanceRecord!);
      }
      return response;
    }
  }

  @override
  Future<Attendance> checkIn({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    double accuracy = 3.0,
    String workLocationId = 'LOC-CAIRO-HQ',
    required bool biometricVerified,
    required bool isOffline,
    DeviceIntegrityResult? integrityResult,
    NetworkRiskInfo? networkRisk,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId ?? _uuid.v4();
    final submission = AttendanceSubmissionRequest(
      clientRequestId: reqId,
      employeeId: employeeId,
      attendanceType: AttendanceType.checkIn,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      clientTimestamp: DateTime.now(),
      workplaceId: workLocationId,
      distanceFromWorkplace: distance,
      biometricVerified: biometricVerified,
      integrityResult: integrityResult,
      networkRisk: networkRisk,
      isOfflineSubmission: isOffline,
    );

    if (!isOffline) {
      final response = await submitAttendanceRequest(submission);
      if (response.success && response.attendanceRecord != null) {
        return response.attendanceRecord!;
      }
    }

    // Local punch record (with offline queuing if offline)
    final record = Attendance(
      id: 'ATT-IN-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: employeeId,
      date: DateTime.now(),
      checkInTime: DateTime.now(),
      status: AttendanceStateType.checkedIn,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distance,
      accuracyMeters: accuracy,
      verificationMethod: 'GPS',
      verificationStatus: isOffline ? 'OFFLINE_PENDING' : 'VERIFIED',
      workLocationId: workLocationId,
      isOfflinePunch: isOffline,
      clientRequestId: reqId,
    );

    if (isOffline) {
      db.queueOfflineAttendance(record);
    } else {
      db.updateAttendanceRecord(record);
    }

    return record;
  }

  @override
  Future<Attendance> checkOut({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    double accuracy = 3.0,
    String workLocationId = 'LOC-CAIRO-HQ',
    required bool biometricVerified,
    required bool isOffline,
    DeviceIntegrityResult? integrityResult,
    NetworkRiskInfo? networkRisk,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId ?? _uuid.v4();
    final submission = AttendanceSubmissionRequest(
      clientRequestId: reqId,
      employeeId: employeeId,
      attendanceType: AttendanceType.checkOut,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      clientTimestamp: DateTime.now(),
      workplaceId: workLocationId,
      distanceFromWorkplace: distance,
      biometricVerified: biometricVerified,
      integrityResult: integrityResult,
      networkRisk: networkRisk,
      isOfflineSubmission: isOffline,
    );

    if (!isOffline) {
      final response = await submitAttendanceRequest(submission);
      if (response.success && response.attendanceRecord != null) {
        return response.attendanceRecord!;
      }
    }

    final today = db.todayAttendanceRecord;
    final record = Attendance(
      id: today?.id ?? 'ATT-OUT-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: employeeId,
      date: today?.date ?? DateTime.now(),
      checkInTime: today?.checkInTime ?? DateTime.now(),
      checkOutTime: DateTime.now(),
      status: AttendanceStateType.checkedOut,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distance,
      accuracyMeters: accuracy,
      verificationMethod: 'GPS',
      verificationStatus: isOffline ? 'OFFLINE_PENDING' : 'VERIFIED',
      workLocationId: workLocationId,
      isOfflinePunch: isOffline,
      clientRequestId: reqId,
    );

    if (isOffline) {
      db.queueOfflineAttendance(record);
    } else {
      db.updateAttendanceRecord(record);
    }

    return record;
  }

  @override
  Future<List<Attendance>> getHistory(String employeeId) async {
    final remoteHistory = await remoteDataSource.getAttendanceHistory();
    if (remoteHistory.isNotEmpty) {
      return remoteHistory;
    }
    return db.attendanceHistory;
  }

  @override
  Future<List<Attendance>> getPendingOfflineQueue() async {
    return db.pendingOfflineSync;
  }

  @override
  Future<int> syncPendingAttendance() async {
    final pending = db.pendingOfflineSync;
    if (pending.isEmpty) return 0;

    int synced = 0;
    for (final punch in List<Attendance>.from(pending)) {
      final submission = AttendanceSubmissionRequest(
        clientRequestId: punch.clientRequestId ?? _uuid.v4(),
        employeeId: punch.employeeId,
        attendanceType: punch.checkOutTime != null
            ? AttendanceType.checkOut
            : AttendanceType.checkIn,
        latitude: punch.latitude ?? 0.0,
        longitude: punch.longitude ?? 0.0,
        accuracy: punch.accuracyMeters ?? 5.0,
        clientTimestamp: punch.checkInTime ?? DateTime.now(),
        workplaceId: punch.workLocationId ?? 'LOC-HQ',
        distanceFromWorkplace: punch.distanceMeters ?? 0.0,
        biometricVerified: true,
        isOfflineSubmission: true,
      );

      final result = await submitAttendanceRequest(submission);
      if (result.success) {
        db.removePendingOfflineSync(punch.id);
        synced++;
      }
    }
    return synced;
  }

  @override
  Future<void> resetToDefaultMock() async {
    db.resetDataKeepSession();
  }
}
