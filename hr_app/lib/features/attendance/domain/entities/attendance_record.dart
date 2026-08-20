import '../../../employees/domain/entities/employee_entity.dart';

enum AttendanceStatus {
  present('PRESENT', 'Present'),
  late('LATE', 'Late'),
  absent('ABSENT', 'Absent'),
  earlyDeparture('EARLY_DEPARTURE', 'Early Departure'),
  overtime('OVERTIME', 'Overtime');

  final String key;
  final String label;

  const AttendanceStatus(this.key, this.label);

  static AttendanceStatus fromKey(String? key) {
    if (key == null) return AttendanceStatus.present;
    return AttendanceStatus.values.firstWhere(
      (s) => s.key.toUpperCase() == key.toUpperCase(),
      orElse: () => AttendanceStatus.present,
    );
  }
}

/// Domain entity representing an employee attendance punch event
class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String workplaceName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceStatus status;
  final int? lateMinutes;
  final int? overtimeMinutes;
  final String? rejectionReason;
  final bool isFlagged;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.workplaceName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.lateMinutes,
    this.overtimeMinutes,
    this.rejectionReason,
    this.isFlagged = false,
  });
}

class AttendanceFilter {
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final AttendanceStatus? status;
  final String? workplaceId;
  final int page;
  final int pageSize;

  const AttendanceFilter({
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.status,
    this.workplaceId,
    this.page = 1,
    this.pageSize = 10,
  });
}

abstract class AttendanceRepository {
  Future<PaginatedList<AttendanceRecord>> getAttendanceRecords(AttendanceFilter filter);
  Future<List<AttendanceRecord>> getTodayAttendance();
  Future<String> exportAttendanceReport(AttendanceFilter filter);
}
