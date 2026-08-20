/// Aggregate KPIs and metrics for HR Dashboard Overview
class DashboardMetrics {
  final int totalEmployees;
  final int presentToday;
  final int lateToday;
  final int absentToday;
  final int pendingRequests;
  final int pendingAdvances;
  final int checkInsToday;
  final int checkOutsToday;
  final double attendanceRate;

  const DashboardMetrics({
    required this.totalEmployees,
    required this.presentToday,
    required this.lateToday,
    required this.absentToday,
    required this.pendingRequests,
    required this.pendingAdvances,
    required this.checkInsToday,
    required this.checkOutsToday,
    required this.attendanceRate,
  });
}

abstract class DashboardRepository {
  Future<DashboardMetrics> getMetrics();
}
