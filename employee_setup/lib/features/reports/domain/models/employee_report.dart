class EmployeeReport {
  final double attendanceRate;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int totalLateMinutes;
  final double totalWorkHours;
  final int approvedLeavesCount;
  final int activeAdvancesCount;
  final int completedTasksCount;
  final int overdueTasksCount;

  const EmployeeReport({
    required this.attendanceRate,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.totalLateMinutes,
    required this.totalWorkHours,
    required this.approvedLeavesCount,
    required this.activeAdvancesCount,
    required this.completedTasksCount,
    required this.overdueTasksCount,
  });

  factory EmployeeReport.fromJson(Map<String, dynamic> json) {
    return EmployeeReport(
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
      presentDays: (json['presentDays'] as num?)?.toInt() ?? 0,
      absentDays: (json['absentDays'] as num?)?.toInt() ?? 0,
      lateDays: (json['lateDays'] as num?)?.toInt() ?? 0,
      totalLateMinutes: (json['totalLateMinutes'] as num?)?.toInt() ?? 0,
      totalWorkHours: (json['totalWorkHours'] as num?)?.toDouble() ?? 0.0,
      approvedLeavesCount: (json['approvedLeavesCount'] as num?)?.toInt() ?? 0,
      activeAdvancesCount: (json['activeAdvancesCount'] as num?)?.toInt() ?? 0,
      completedTasksCount: (json['completedTasksCount'] as num?)?.toInt() ?? 0,
      overdueTasksCount: (json['overdueTasksCount'] as num?)?.toInt() ?? 0,
    );
  }
}
