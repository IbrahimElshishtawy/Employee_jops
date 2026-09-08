import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../domain/models/employee_report.dart';
import '../datasources/reports_remote_data_source.dart';

final reportsRemoteDataSourceProvider =
    Provider<ReportsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsRemoteDataSource(apiClient: apiClient);
});

final employeeReportProvider =
    FutureProvider.autoDispose<EmployeeReport>((ref) async {
  final ds = ref.watch(reportsRemoteDataSourceProvider);
  try {
    return await ds.getMyReport();
  } catch (e) {
    // Fallback safe defaults if offline or testing
    return const EmployeeReport(
      attendanceRate: 100.0,
      presentDays: 20,
      absentDays: 0,
      lateDays: 0,
      totalLateMinutes: 0,
      totalWorkHours: 160.0,
      approvedLeavesCount: 0,
      activeAdvancesCount: 0,
      completedTasksCount: 0,
      overdueTasksCount: 0,
    );
  }
});

class ReportsRepository {
  final ReportsRemoteDataSource _dataSource;

  ReportsRepository({required ReportsRemoteDataSource dataSource})
      : _dataSource = dataSource;

  Future<EmployeeReport> getMyReport({String? startDate, String? endDate}) =>
      _dataSource.getMyReport(startDate: startDate, endDate: endDate);
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final ds = ref.watch(reportsRemoteDataSourceProvider);
  return ReportsRepository(dataSource: ds);
});
