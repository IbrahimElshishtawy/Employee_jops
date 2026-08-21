import 'package:flutter/material.dart';
import '../../domain/entities/report_entities.dart';

enum ReportsTab {
  overview('Executive Overview'),
  attendance('Attendance Analytics'),
  lateArrivals('Late Arrivals Audit'),
  departments('Department Breakdown'),
  financials('Advances & Deductions');

  final String label;
  const ReportsTab(this.label);
}

/// State Controller for HR Reports & Analytics
class ReportsController extends ChangeNotifier {
  final ReportsRepository _repository;

  ReportsTab _activeTab = ReportsTab.overview;
  ReportFilter _filter = const ReportFilter();
  bool _isLoading = false;
  String? _errorMessage;

  ReportOverviewSummary? _overview;
  List<AttendanceDailyTrend> _trends = [];
  List<DepartmentAttendanceMetric> _departments = [];
  List<LateArrivalReportItem> _lateArrivals = [];
  List<WorkforceDistributionMetric> _workforceDistribution = [];

  ReportsController(this._repository) {
    loadReports();
  }

  ReportsTab get activeTab => _activeTab;
  ReportFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReportOverviewSummary? get overview => _overview;
  List<AttendanceDailyTrend> get trends => _trends;
  List<DepartmentAttendanceMetric> get departments => _departments;
  List<LateArrivalReportItem> get lateArrivals => _lateArrivals;
  List<WorkforceDistributionMetric> get workforceDistribution => _workforceDistribution;

  void setActiveTab(ReportsTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void setDatePreset(DateRangePreset preset) {
    _filter = _filter.copyWith(datePreset: preset);
    loadReports();
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    _filter = _filter.copyWith(
      datePreset: DateRangePreset.custom,
      startDate: start,
      endDate: end,
    );
    loadReports();
  }

  void setDepartment(String? department) {
    _filter = _filter.copyWith(department: department);
    loadReports();
  }

  void setWorkplace(String? workplaceId) {
    _filter = _filter.copyWith(workplaceId: workplaceId);
    loadReports();
  }

  Future<void> loadReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getOverviewSummary(_filter),
        _repository.getAttendanceTrends(_filter),
        _repository.getDepartmentBreakdown(_filter),
        _repository.getLateArrivalsReport(_filter),
        _repository.getWorkforceDistribution(),
      ]);

      _overview = results[0] as ReportOverviewSummary;
      _trends = results[1] as List<AttendanceDailyTrend>;
      _departments = results[2] as List<DepartmentAttendanceMetric>;
      _lateArrivals = results[3] as List<LateArrivalReportItem>;
      _workforceDistribution = results[4] as List<WorkforceDistributionMetric>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> exportReport(String reportType, String format) async {
    return await _repository.exportReport(
      reportType: reportType,
      filter: _filter,
      format: format,
    );
  }
}
