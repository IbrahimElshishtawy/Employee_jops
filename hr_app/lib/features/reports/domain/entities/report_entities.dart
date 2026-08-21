/// Top-level executive overview KPI metrics
class ReportOverviewSummary {
  final int totalEmployees;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int earlyCheckoutCount;
  final int pendingRequestsCount;
  final double approvedAdvancesAmount;
  final double totalDeductionsAmount;
  final double attendanceRate; // e.g. 92.5%
  final double punctualityRate;  // e.g. 88.0%

  const ReportOverviewSummary({
    required this.totalEmployees,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.earlyCheckoutCount,
    required this.pendingRequestsCount,
    required this.approvedAdvancesAmount,
    required this.totalDeductionsAmount,
    required this.attendanceRate,
    required this.punctualityRate,
  });
}

/// Daily aggregated attendance & punctuality trend data point
class AttendanceDailyTrend {
  final DateTime date;
  final int present;
  final int absent;
  final int late;
  final int earlyCheckout;
  final double attendanceRate;

  const AttendanceDailyTrend({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
    required this.earlyCheckout,
    required this.attendanceRate,
  });
}

/// Departmental attendance compliance & headcount comparison
class DepartmentAttendanceMetric {
  final String department;
  final int headcount;
  final double presentRate;
  final int lateCount;
  final int absenceCount;

  const DepartmentAttendanceMetric({
    required this.department,
    required this.headcount,
    required this.presentRate,
    required this.lateCount,
    required this.absenceCount,
  });
}

/// Detailed audit item for late arrivals
class LateArrivalReportItem {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final DateTime date;
  final String scheduledStartTime;
  final String actualCheckInTime;
  final int lateMinutes;
  final bool hasApprovedExcuse;

  const LateArrivalReportItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.date,
    required this.scheduledStartTime,
    required this.actualCheckInTime,
    required this.lateMinutes,
    required this.hasApprovedExcuse,
  });
}

/// Workforce category distribution metric
class WorkforceDistributionMetric {
  final String label;
  final int count;
  final double percentage;

  const WorkforceDistributionMetric({
    required this.label,
    required this.count,
    required this.percentage,
  });
}

enum DateRangePreset {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  custom('Custom Range');

  final String label;
  const DateRangePreset(this.label);
}

class ReportFilter {
  final DateRangePreset datePreset;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? department;
  final String? workplaceId;

  const ReportFilter({
    this.datePreset = DateRangePreset.thisMonth,
    this.startDate,
    this.endDate,
    this.department,
    this.workplaceId,
  });

  ReportFilter copyWith({
    DateRangePreset? datePreset,
    DateTime? startDate,
    DateTime? endDate,
    String? department,
    String? workplaceId,
  }) {
    return ReportFilter(
      datePreset: datePreset ?? this.datePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      department: department ?? this.department,
      workplaceId: workplaceId ?? this.workplaceId,
    );
  }
}

abstract class ReportsRepository {
  Future<ReportOverviewSummary> getOverviewSummary(ReportFilter filter);
  Future<List<AttendanceDailyTrend>> getAttendanceTrends(ReportFilter filter);
  Future<List<DepartmentAttendanceMetric>> getDepartmentBreakdown(ReportFilter filter);
  Future<List<LateArrivalReportItem>> getLateArrivalsReport(ReportFilter filter);
  Future<List<WorkforceDistributionMetric>> getWorkforceDistribution();
  Future<String> exportReport({
    required String reportType,
    required ReportFilter filter,
    required String format, // 'CSV', 'PDF', 'XLSX'
  });
}
