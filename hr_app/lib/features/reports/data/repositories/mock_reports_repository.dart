import '../../domain/entities/report_entities.dart';

/// Mock implementation of ReportsRepository with realistic analytical figures
class MockReportsRepository implements ReportsRepository {
  @override
  Future<ReportOverviewSummary> getOverviewSummary(ReportFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const ReportOverviewSummary(
      totalEmployees: 48,
      presentCount: 44,
      absentCount: 2,
      lateCount: 4,
      earlyCheckoutCount: 1,
      pendingRequestsCount: 7,
      approvedAdvancesAmount: 23500.0,
      totalDeductionsAmount: 4350.0,
      attendanceRate: 91.67,
      punctualityRate: 90.91,
    );
  }

  @override
  Future<List<AttendanceDailyTrend>> getAttendanceTrends(ReportFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    return [
      AttendanceDailyTrend(
        date: now.subtract(const Duration(days: 6)),
        present: 45,
        absent: 2,
        late: 3,
        earlyCheckout: 1,
        attendanceRate: 93.75,
      ),
      AttendanceDailyTrend(
        date: now.subtract(const Duration(days: 5)),
        present: 46,
        absent: 1,
        late: 2,
        earlyCheckout: 0,
        attendanceRate: 95.83,
      ),
      AttendanceDailyTrend(
        date: now.subtract(const Duration(days: 4)),
        present: 43,
        absent: 4,
        late: 5,
        earlyCheckout: 2,
        attendanceRate: 89.58,
      ),
      AttendanceDailyTrend(
        date: now.subtract(const Duration(days: 3)),
        present: 44,
        absent: 3,
        late: 4,
        earlyCheckout: 1,
        attendanceRate: 91.67,
      ),
      AttendanceDailyTrend(
        date: now.subtract(const Duration(days: 2)),
        present: 45,
        absent: 2,
        late: 2,
        earlyCheckout: 0,
        attendanceRate: 93.75,
      ),
      AttendanceDailyTrend(
        date: now.subtract(const Duration(days: 1)),
        present: 42,
        absent: 5,
        late: 6,
        earlyCheckout: 2,
        attendanceRate: 87.50,
      ),
      AttendanceDailyTrend(
        date: now,
        present: 44,
        absent: 2,
        late: 4,
        earlyCheckout: 1,
        attendanceRate: 91.67,
      ),
    ];
  }

  @override
  Future<List<DepartmentAttendanceMetric>> getDepartmentBreakdown(ReportFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      DepartmentAttendanceMetric(
        department: 'Engineering',
        headcount: 22,
        presentRate: 95.45,
        lateCount: 2,
        absenceCount: 1,
      ),
      DepartmentAttendanceMetric(
        department: 'Operations',
        headcount: 12,
        presentRate: 91.67,
        lateCount: 1,
        absenceCount: 1,
      ),
      DepartmentAttendanceMetric(
        department: 'Human Resources',
        headcount: 6,
        presentRate: 100.0,
        lateCount: 0,
        absenceCount: 0,
      ),
      DepartmentAttendanceMetric(
        department: 'Finance',
        headcount: 5,
        presentRate: 80.0,
        lateCount: 1,
        absenceCount: 1,
      ),
      DepartmentAttendanceMetric(
        department: 'Marketing',
        headcount: 3,
        presentRate: 100.0,
        lateCount: 0,
        absenceCount: 0,
      ),
    ];
  }

  @override
  Future<List<LateArrivalReportItem>> getLateArrivalsReport(ReportFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final today = DateTime.now();
    return [
      LateArrivalReportItem(
        id: 'LATE-001',
        employeeId: 'EMP-004',
        employeeName: 'Omar Khaled',
        employeeCode: 'EMP-1004',
        department: 'Engineering',
        date: today,
        scheduledStartTime: '09:00',
        actualCheckInTime: '09:42',
        lateMinutes: 42,
        hasApprovedExcuse: false,
      ),
      LateArrivalReportItem(
        id: 'LATE-002',
        employeeId: 'EMP-007',
        employeeName: 'Hassan Mahmoud',
        employeeCode: 'EMP-1007',
        department: 'Operations',
        date: today,
        scheduledStartTime: '08:00',
        actualCheckInTime: '08:28',
        lateMinutes: 28,
        hasApprovedExcuse: true,
      ),
      LateArrivalReportItem(
        id: 'LATE-003',
        employeeId: 'EMP-009',
        employeeName: 'Youssef Nabil',
        employeeCode: 'EMP-1009',
        department: 'Finance',
        date: today.subtract(const Duration(days: 1)),
        scheduledStartTime: '09:00',
        actualCheckInTime: '09:35',
        lateMinutes: 35,
        hasApprovedExcuse: false,
      ),
      LateArrivalReportItem(
        id: 'LATE-004',
        employeeId: 'EMP-012',
        employeeName: 'Mariam Adel',
        employeeCode: 'EMP-1012',
        department: 'Engineering',
        date: today.subtract(const Duration(days: 1)),
        scheduledStartTime: '10:00',
        actualCheckInTime: '10:19',
        lateMinutes: 19,
        hasApprovedExcuse: true,
      ),
    ];
  }

  @override
  Future<List<WorkforceDistributionMetric>> getWorkforceDistribution() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const [
      WorkforceDistributionMetric(label: 'Engineering', count: 22, percentage: 45.8),
      WorkforceDistributionMetric(label: 'Operations', count: 12, percentage: 25.0),
      WorkforceDistributionMetric(label: 'Human Resources', count: 6, percentage: 12.5),
      WorkforceDistributionMetric(label: 'Finance', count: 5, percentage: 10.4),
      WorkforceDistributionMetric(label: 'Marketing', count: 3, percentage: 6.3),
    ];
  }

  @override
  Future<String> exportReport({
    required String reportType,
    required ReportFilter filter,
    required String format,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return 'https://cyberwise.test/exports/$reportType-${filter.datePreset.name.toLowerCase()}.$format';
  }
}
