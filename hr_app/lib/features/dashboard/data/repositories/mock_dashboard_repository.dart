import '../../domain/entities/dashboard_metrics.dart';

/// Mock Dashboard Repository with realistic test metrics
class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardMetrics> getMetrics() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return const DashboardMetrics(
      totalEmployees: 48,
      presentToday: 42,
      lateToday: 3,
      absentToday: 3,
      pendingRequests: 7,
      pendingAdvances: 4,
      checkInsToday: 45,
      checkOutsToday: 21,
      attendanceRate: 87.5,
    );
  }
}
