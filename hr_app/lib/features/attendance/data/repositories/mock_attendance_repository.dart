import '../../../employees/domain/entities/employee_entity.dart';
import '../../domain/entities/attendance_record.dart';

/// Mock Attendance Repository with safe test records
class MockAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> _mockRecords = [
    AttendanceRecord(
      id: 'TEST-ATT-001',
      employeeId: 'TEST-EMP-001',
      employeeName: 'Alex Vance (Test)',
      employeeCode: 'CW-001',
      workplaceName: 'HQ Main Tower',
      date: DateTime.now(),
      checkInTime: DateTime.now().subtract(const Duration(hours: 6)),
      checkOutTime: null,
      status: AttendanceStatus.present,
    ),
    AttendanceRecord(
      id: 'TEST-ATT-002',
      employeeId: 'TEST-EMP-002',
      employeeName: 'Jordan Miller (Test)',
      employeeCode: 'CW-002',
      workplaceName: 'HQ Main Tower',
      date: DateTime.now(),
      checkInTime: DateTime.now().subtract(const Duration(hours: 5, minutes: 20)),
      checkOutTime: null,
      status: AttendanceStatus.late,
      lateMinutes: 20,
    ),
    AttendanceRecord(
      id: 'TEST-ATT-003',
      employeeId: 'TEST-EMP-003',
      employeeName: 'Taylor Morgan (Test)',
      employeeCode: 'CW-003',
      workplaceName: 'Tech Hub Branch',
      date: DateTime.now(),
      checkInTime: null,
      checkOutTime: null,
      status: AttendanceStatus.absent,
    ),
    AttendanceRecord(
      id: 'TEST-ATT-004',
      employeeId: 'TEST-EMP-004',
      employeeName: 'Samira Khan (Test)',
      employeeCode: 'CW-004',
      workplaceName: 'HQ Main Tower',
      date: DateTime.now().subtract(const Duration(days: 1)),
      checkInTime: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      checkOutTime: DateTime.now().subtract(const Duration(days: 1)),
      status: AttendanceStatus.overtime,
      overtimeMinutes: 45,
    ),
    AttendanceRecord(
      id: 'TEST-ATT-005',
      employeeId: 'TEST-EMP-005',
      employeeName: 'Casey Davis (Test)',
      employeeCode: 'CW-005',
      workplaceName: 'Tech Hub Branch',
      date: DateTime.now().subtract(const Duration(days: 1)),
      checkInTime: DateTime.now().subtract(const Duration(days: 1, hours: 7)),
      checkOutTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      status: AttendanceStatus.earlyDeparture,
    ),
  ];

  @override
  Future<PaginatedList<AttendanceRecord>> getAttendanceRecords(AttendanceFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var results = List<AttendanceRecord>.from(_mockRecords);

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      results = results.where((r) =>
          r.employeeName.toLowerCase().contains(q) ||
          r.employeeCode.toLowerCase().contains(q) ||
          r.workplaceName.toLowerCase().contains(q)).toList();
    }

    if (filter.status != null) {
      results = results.where((r) => r.status == filter.status).toList();
    }

    final totalCount = results.length;
    final totalPages = (totalCount / filter.pageSize).ceil().clamp(1, 999);
    final startIndex = ((filter.page - 1) * filter.pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + filter.pageSize).clamp(0, totalCount);

    return PaginatedList<AttendanceRecord>(
      items: results.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<List<AttendanceRecord>> getTodayAttendance() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockRecords.where((r) => r.date.day == DateTime.now().day).toList();
  }

  @override
  Future<String> exportAttendanceReport(AttendanceFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return 'https://reports.cyberwise.internal/downloads/attendance_export_mock.csv';
  }
}
