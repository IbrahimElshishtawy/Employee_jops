import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/models/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  final LocalStorage storage;
  final Uuid _uuid = const Uuid();

  TodayAttendanceSummary _todaySummary = const TodayAttendanceSummary();
  final List<Attendance> _history = [];
  final List<Attendance> _offlineQueue = [];

  MockAttendanceRepository(this.storage) {
    _initializeMockHistory();
  }

  void _initializeMockHistory() {
    _history.clear();
    _offlineQueue.clear();
    _todaySummary = const TodayAttendanceSummary();

    final now = DateTime.now();
    // Previous days records
    _history.addAll([
      Attendance(
        id: 'att-101',
        employeeId: AppConstants.mockEmployeeId,
        type: AttendanceType.checkIn,
        timestamp: DateTime(now.year, now.month, now.day - 1, 8, 45),
        latitude: AppConstants.officeLatitude,
        longitude: AppConstants.officeLongitude,
        distanceFromOffice: 1.8,
        biometricVerified: true,
        isOffline: false,
        status: AttendanceStatus.success,
      ),
      Attendance(
        id: 'att-102',
        employeeId: AppConstants.mockEmployeeId,
        type: AttendanceType.checkOut,
        timestamp: DateTime(now.year, now.month, now.day - 1, 17, 10),
        latitude: AppConstants.officeLatitude,
        longitude: AppConstants.officeLongitude,
        distanceFromOffice: 2.1,
        biometricVerified: true,
        isOffline: false,
        status: AttendanceStatus.success,
      ),
      Attendance(
        id: 'att-103',
        employeeId: AppConstants.mockEmployeeId,
        type: AttendanceType.checkIn,
        timestamp: DateTime(now.year, now.month, now.day - 2, 8, 52),
        latitude: AppConstants.officeLatitude,
        longitude: AppConstants.officeLongitude,
        distanceFromOffice: 2.5,
        biometricVerified: true,
        isOffline: false,
        status: AttendanceStatus.success,
      ),
      Attendance(
        id: 'att-104',
        employeeId: AppConstants.mockEmployeeId,
        type: AttendanceType.checkOut,
        timestamp: DateTime(now.year, now.month, now.day - 2, 17, 05),
        latitude: AppConstants.officeLatitude,
        longitude: AppConstants.officeLongitude,
        distanceFromOffice: 1.9,
        biometricVerified: true,
        isOffline: false,
        status: AttendanceStatus.success,
      ),
    ]);

    // Restore from storage if saved
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final pendingRaw = storage.getStringList(AppConstants.keyPendingAttendance);
    if (pendingRaw != null) {
      _offlineQueue.clear();
      for (final item in pendingRaw) {
        try {
          _offlineQueue.add(Attendance.fromJson(jsonDecode(item)));
        } catch (_) {}
      }
    }
  }

  Future<void> _savePendingQueue() async {
    final list = _offlineQueue.map((e) => jsonEncode(e.toJson())).toList();
    await storage.setStringList(AppConstants.keyPendingAttendance, list);
  }

  @override
  Future<TodayAttendanceSummary> getTodayStatus(String employeeId) async {
    return _todaySummary;
  }

  @override
  Future<Attendance> checkIn({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    required bool biometricVerified,
    required bool isOffline,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final record = Attendance(
      id: _uuid.v4(),
      employeeId: employeeId,
      type: AttendanceType.checkIn,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      distanceFromOffice: distance,
      biometricVerified: biometricVerified,
      isOffline: isOffline,
      status: isOffline ? AttendanceStatus.offlinePending : AttendanceStatus.success,
      note: isOffline ? 'تم التسجيل في وضع عدم الاتصال (Pending HR)' : null,
    );

    _todaySummary = _todaySummary.copyWith(checkIn: record);
    _history.insert(0, record);

    if (isOffline) {
      _offlineQueue.add(record);
      await _savePendingQueue();
    }

    return record;
  }

  @override
  Future<Attendance> checkOut({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double distance,
    required bool biometricVerified,
    required bool isOffline,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final record = Attendance(
      id: _uuid.v4(),
      employeeId: employeeId,
      type: AttendanceType.checkOut,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      distanceFromOffice: distance,
      biometricVerified: biometricVerified,
      isOffline: isOffline,
      status: isOffline ? AttendanceStatus.offlinePending : AttendanceStatus.success,
      note: isOffline ? 'تم تسجيل الانصراف في وضع عدم الاتصال' : null,
    );

    _todaySummary = _todaySummary.copyWith(checkOut: record);
    _history.insert(0, record);

    if (isOffline) {
      _offlineQueue.add(record);
      await _savePendingQueue();
    }

    return record;
  }

  @override
  Future<List<Attendance>> getHistory(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_history);
  }

  @override
  Future<List<Attendance>> getPendingOfflineQueue() async {
    return List.unmodifiable(_offlineQueue);
  }

  @override
  Future<int> syncPendingAttendance() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final count = _offlineQueue.length;
    _offlineQueue.clear();
    await _savePendingQueue();
    return count;
  }

  @override
  Future<void> resetToDefaultMock() async {
    _initializeMockHistory();
    await _savePendingQueue();
  }
}
